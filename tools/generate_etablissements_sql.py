#!/usr/bin/env python3
"""Parse static Dart venue data files and generate SQL INSERT statements."""
import re
import os

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

def escape_sql(s):
    """Escape single quotes for SQL."""
    return s.replace("'", "''")

def extract_dart_strings(block):
    """Extract field: value pairs from a Dart constructor block.
    Handles both 'single quoted' and "double quoted" strings,
    including Dart's \\' escape inside single-quoted strings."""
    entry = {}

    # Single-quoted strings with \' escape support
    for m in re.finditer(r"(\w+):\s*'((?:[^'\\]|\\.)*)'", block):
        val = m.group(2).replace("\\'", "'")
        entry[m.group(1)] = val

    # Double-quoted strings
    for m in re.finditer(r'(\w+):\s*"((?:[^"\\]|\\.)*)"', block):
        val = m.group(2).replace('\\"', '"')
        entry[m.group(1)] = val

    # Numeric fields (doubles)
    for m in re.finditer(r'(\w+):\s*(-?[0-9]+\.[0-9]+)', block):
        if m.group(1) not in entry:  # don't overwrite string matches
            entry[m.group(1)] = m.group(2)

    # Boolean/null
    for m in re.finditer(r'(\w+):\s*(true|false|null)\b', block):
        if m.group(1) not in entry:
            entry[m.group(1)] = m.group(2)

    return entry

def parse_commerce_models(filepath):
    """Parse CommerceModel entries from a Dart file."""
    with open(filepath) as f:
        content = f.read()

    entries = []
    # Find each CommerceModel( block with balanced parens
    starts = [m.start() for m in re.finditer(r'CommerceModel\(', content)]
    for s in starts:
        # Find balanced closing paren
        open_pos = content.index('(', s)
        depth = 1
        i = open_pos + 1
        while i < len(content) and depth > 0:
            if content[i] == '(':
                depth += 1
            elif content[i] == ')':
                depth -= 1
            i += 1
        block = content[open_pos+1:i-1]
        entry = extract_dart_strings(block)
        if entry.get('nom'):
            entries.append(entry)
    return entries

def parse_typed_venues(filepath, name_field='name'):
    """Parse typed venue entries (CinemaVenue, BowlingVenue, etc.)."""
    with open(filepath) as f:
        content = f.read()

    entries = []
    # Find all XxxVenue( constructor calls (but skip the class definition)
    starts = [m.start() for m in re.finditer(r'\b\w+Venue\(', content)]

    for s in starts:
        # Skip class constructor definition (const ClassName({)
        line_start = content.rfind('\n', 0, s)
        line = content[line_start:s+30]
        if 'const' in line and '{' in content[s:s+50] and 'required' in content[s:s+200]:
            continue

        open_pos = content.index('(', s)
        depth = 1
        i = open_pos + 1
        while i < len(content) and depth > 0:
            if content[i] == '(' :
                depth += 1
            elif content[i] == ')':
                depth -= 1
            i += 1
        block = content[open_pos+1:i-1]

        entry = extract_dart_strings(block)

        if entry.get(name_field) or entry.get('name') or entry.get('nom'):
            entries.append(entry)
    return entries

def format_insert(entries, rubrique, categorie, field_map=None):
    """Format entries as SQL INSERT VALUES tuples."""
    if not entries:
        return ""

    lines = []
    for e in entries:
        if field_map:
            nom = e.get(field_map.get('nom', 'nom'), e.get('name', ''))
        else:
            nom = e.get('nom', e.get('name', ''))

        adresse = e.get('adresse', '')
        ville = e.get('ville', 'Toulouse')
        tel = e.get('telephone', '')
        horaires = e.get('horaires', '')
        site_web = e.get('siteWeb', e.get('websiteUrl', e.get('site_web', '')))
        if site_web == 'null':
            site_web = ''
        lien_maps = e.get('lienMaps', e.get('lien_maps', ''))
        photo = e.get('photo', e.get('image', ''))
        lat = e.get('latitude', '0')
        lon = e.get('longitude', '0')
        cat = e.get('categorie', categorie) if categorie == '__from_data__' else categorie

        lines.append(
            f"('{escape_sql(nom)}', '{rubrique}', '{escape_sql(cat)}', "
            f"'{escape_sql(adresse)}', '{escape_sql(ville)}', '{escape_sql(tel)}', "
            f"'{escape_sql(horaires)}', '{escape_sql(site_web)}', '{escape_sql(lien_maps)}', "
            f"'{escape_sql(photo)}', {lat}, {lon})"
        )
    return lines

def main():
    all_lines = []

    # ---- NUIT ----
    print("-- Parsing nuit bars...")
    bars = parse_commerce_models(os.path.join(BASE, 'lib/features/night/data/night_bars_data.dart'))
    nuit_lines = format_insert(bars, 'nuit', '__from_data__')
    all_lines.extend(nuit_lines)
    print(f"  -> {len(nuit_lines)} bars")

    # ---- FAMILLE ----
    famille_files = [
        ('lib/features/family/data/cinema_venues_data.dart', 'Cinema'),
        ('lib/features/family/data/bowling_venues_data.dart', 'Bowling'),
        ('lib/features/family/data/laser_game_venues_data.dart', 'Laser game'),
        ('lib/features/family/data/escape_game_venues_data.dart', 'Escape game'),
        ('lib/features/family/data/playground_venues_data.dart', 'Aire de jeux'),
        ('lib/features/family/data/family_restaurant_venues_data.dart', 'Restaurant familial'),
        ('lib/features/family/data/animal_park_venues_data.dart', 'Parc animalier'),
        ('lib/features/family/data/farm_venues_data.dart', 'Ferme pedagogique'),
        ('lib/features/family/data/ice_rink_venues_data.dart', 'Patinoire'),
    ]

    for fpath, cat in famille_files:
        full = os.path.join(BASE, fpath)
        if not os.path.exists(full):
            print(f"  SKIP {fpath} (not found)")
            continue
        venues = parse_typed_venues(full)
        lines = format_insert(venues, 'famille', cat)
        all_lines.extend(lines)
        print(f"  -> {len(lines)} {cat}")

    # Park venues use CommerceModel
    park_file = os.path.join(BASE, 'lib/features/family/data/park_venues_data.dart')
    if os.path.exists(park_file):
        parks = parse_commerce_models(park_file)
        lines = format_insert(parks, 'famille', "Parc d'attractions")
        all_lines.extend(lines)
        print(f"  -> {len(lines)} Parc d'attractions")

    # ---- CULTURE ----
    culture_typed = [
        ('lib/features/culture/data/museum_venues_data.dart', 'Musee'),
        ('lib/features/culture/data/theatre_venues_data.dart', 'Theatre'),
        ('lib/features/culture/data/monument_venues_data.dart', 'Monument'),
        ('lib/features/culture/data/library_venues_data.dart', 'Bibliotheque'),
    ]

    for fpath, cat in culture_typed:
        full = os.path.join(BASE, fpath)
        if not os.path.exists(full):
            print(f"  SKIP {fpath} (not found)")
            continue
        venues = parse_typed_venues(full)
        lines = format_insert(venues, 'culture', cat)
        all_lines.extend(lines)
        print(f"  -> {len(lines)} {cat}")

    # Gallery uses CommerceModel
    gallery_file = os.path.join(BASE, 'lib/features/culture/data/gallery_venues_data.dart')
    if os.path.exists(gallery_file):
        galleries = parse_commerce_models(gallery_file)
        lines = format_insert(galleries, 'culture', 'Galerie')
        all_lines.extend(lines)
        print(f"  -> {len(lines)} Galerie")

    # ---- FOOD ----
    food_file = os.path.join(BASE, 'lib/features/food/data/restaurant_venues_data.dart')
    if os.path.exists(food_file):
        restaurants = parse_typed_venues(food_file)
        lines = format_insert(restaurants, 'food', 'Restaurant insolite')
        all_lines.extend(lines)
        print(f"  -> {len(lines)} Restaurant insolite")

    # Output full SQL
    print(f"\nTotal entries: {len(all_lines)}")

    sql_header = """-- Migration: etablissements table
-- Single table for all venue types (nuit, famille, culture, food)

-- =============================================
-- TABLE
-- =============================================
CREATE TABLE public.etablissements (
  id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nom         TEXT NOT NULL,
  rubrique    TEXT NOT NULL,
  categorie   TEXT NOT NULL DEFAULT '',
  adresse     TEXT NOT NULL DEFAULT '',
  ville       TEXT NOT NULL DEFAULT 'Toulouse',
  telephone   TEXT NOT NULL DEFAULT '',
  horaires    TEXT NOT NULL DEFAULT '',
  site_web    TEXT NOT NULL DEFAULT '',
  lien_maps   TEXT NOT NULL DEFAULT '',
  photo       TEXT NOT NULL DEFAULT '',
  latitude    DOUBLE PRECISION NOT NULL DEFAULT 0,
  longitude   DOUBLE PRECISION NOT NULL DEFAULT 0,
  is_active   BOOLEAN NOT NULL DEFAULT TRUE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================
-- INDEXES
-- =============================================
CREATE INDEX idx_etablissements_rubrique ON public.etablissements (rubrique);
CREATE INDEX idx_etablissements_active ON public.etablissements (is_active);

-- =============================================
-- RLS
-- =============================================
ALTER TABLE public.etablissements ENABLE ROW LEVEL SECURITY;
CREATE POLICY "anon_read" ON public.etablissements FOR SELECT USING (true);
CREATE POLICY "service_write" ON public.etablissements FOR ALL USING (auth.role() = 'service_role');

-- =============================================
-- SEED DATA
-- =============================================
"""

    sql_insert = "INSERT INTO public.etablissements (nom, rubrique, categorie, adresse, ville, telephone, horaires, site_web, lien_maps, photo, latitude, longitude) VALUES\n"
    sql_values = ",\n".join(all_lines)
    sql_insert += sql_values + ";\n"

    output_path = os.path.join(BASE, 'supabase/migrations/20260307200000_etablissements.sql')
    with open(output_path, 'w') as f:
        f.write(sql_header)
        f.write(sql_insert)

    print(f"\nSQL written to: {output_path}")

if __name__ == '__main__':
    main()
