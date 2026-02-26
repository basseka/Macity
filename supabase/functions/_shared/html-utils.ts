// Shared HTML / date utilities for all scraper edge functions.

/** Strip HTML tags and decode common entities. */
export function cleanHtml(text: string): string {
  return text
    .replace(/<[^>]*>/g, "")
    .replace(/&nbsp;/g, " ")
    .replace(/&amp;/g, "&")
    .replace(/&quot;/g, '"')
    .replace(/&#039;/g, "'")
    .replace(/&rsquo;/g, "\u2019")
    .replace(/&lsquo;/g, "\u2018")
    .replace(/&rdquo;/g, "\u201D")
    .replace(/&ldquo;/g, "\u201C")
    .replace(/&#8211;/g, "\u2013")
    .replace(/&#8217;/g, "\u2019")
    .replace(/\s+/g, " ")
    .trim();
}

/** French month name → month number (1-12). */
export const frenchMonths: Record<string, number> = {
  janvier: 1, jan: 1, janv: 1,
  fevrier: 2, "février": 2, fev: 2, "févr": 2,
  mars: 3, mar: 3,
  avril: 4, avr: 4,
  mai: 5,
  juin: 6,
  juillet: 7, juil: 7,
  aout: 8, "août": 8,
  septembre: 9, sept: 9, sep: 9,
  octobre: 10, oct: 10,
  novembre: 11, nov: 11,
  decembre: 12, "décembre": 12, dec: 12, "déc": 12,
};

/** Build ISO date "YYYY-MM-DD" from day, French month name, year. */
export function buildIsoDate(day: string, month: string, year: string): string | null {
  const d = parseInt(day, 10);
  const y = parseInt(year, 10);
  const monthClean = month.toLowerCase().replace(".", "");
  const m = frenchMonths[monthClean];
  if (isNaN(d) || isNaN(y) || !m) return null;
  return `${y}-${String(m).padStart(2, "0")}-${String(d).padStart(2, "0")}`;
}

/** Convert "20 juin" → "2026-06-20" (current or next year). */
export function frenchDateToIso(dateText: string | null): string | null {
  if (!dateText) return null;
  const match = dateText.match(/(\d{1,2})\s+(\w+)/);
  if (!match) return null;

  const day = parseInt(match[1], 10);
  const monthStr = match[2].toLowerCase();
  const month = frenchMonths[monthStr];
  if (isNaN(day) || !month) return null;

  const now = new Date();
  let year = now.getFullYear();
  const candidate = new Date(year, month - 1, day);
  const cutoff = new Date(now);
  cutoff.setDate(cutoff.getDate() - 30);
  if (candidate < cutoff) year++;

  return `${year}-${String(month).padStart(2, "0")}-${String(day).padStart(2, "0")}`;
}

/** Current theatre season year (sept-dec → next year, jan-aug → current year). */
export function currentSeasonYear(): string {
  const now = new Date();
  return now.getMonth() >= 8 ? `${now.getFullYear() + 1}` : `${now.getFullYear()}`;
}

/** ISO datetime string → "YYYY-MM-DD" */
export function isoToDate(iso: string): string {
  if (!iso) return "";
  const dt = new Date(iso);
  if (isNaN(dt.getTime())) return "";
  return `${dt.getFullYear()}-${String(dt.getMonth() + 1).padStart(2, "0")}-${String(dt.getDate()).padStart(2, "0")}`;
}

/** ISO datetime string → "HHhMM" */
export function isoToTime(iso: string): string {
  if (!iso) return "";
  const dt = new Date(iso);
  if (isNaN(dt.getTime())) return "";
  return `${String(dt.getHours()).padStart(2, "0")}h${String(dt.getMinutes()).padStart(2, "0")}`;
}

/** Fetch HTML with timeout and User-Agent. */
export async function fetchHtml(url: string, timeoutMs = 8000): Promise<string> {
  const controller = new AbortController();
  const id = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const res = await fetch(url, {
      headers: {
        "User-Agent": "Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 Chrome/120",
      },
      signal: controller.signal,
    });
    return await res.text();
  } finally {
    clearTimeout(id);
  }
}

/** Fetch JSON with timeout and User-Agent. */
export async function fetchJson<T = unknown>(url: string, timeoutMs = 10000): Promise<T> {
  const controller = new AbortController();
  const id = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const res = await fetch(url, {
      headers: {
        "User-Agent": "Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 Chrome/120",
      },
      signal: controller.signal,
    });
    return await res.json();
  } finally {
    clearTimeout(id);
  }
}
