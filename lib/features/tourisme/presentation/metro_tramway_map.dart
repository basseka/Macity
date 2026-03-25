import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Carte interactive du réseau Métro & Tramway de Toulouse (Tisseo).
class MetroTramwayMap extends StatefulWidget {
  const MetroTramwayMap({super.key});

  @override
  State<MetroTramwayMap> createState() => _MetroTramwayMapState();
}

class _MetroTramwayMapState extends State<MetroTramwayMap> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent('PulzApp/1.0 (https://pulzapp.fr)')
      ..addJavaScriptChannel(
        'FlutterLocation',
        onMessageReceived: (_) => _handleLocationRequest(),
      )
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) {
          if (mounted) setState(() => _isLoading = false);
        },
      ))
      ..loadHtmlString(_buildHtml());
  }

  Future<void> _handleLocationRequest() async {
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (!mounted) return;
      _controller.runJavaScript('onLocationSuccess(${pos.latitude}, ${pos.longitude})');
    } catch (e) {
      debugPrint('[MetroTramwayMap] location error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WebViewWidget(
          controller: _controller,
          gestureRecognizers: {Factory(() => EagerGestureRecognizer())},
        ),
        if (_isLoading)
          const Center(child: CircularProgressIndicator(color: Color(0xFFE91E8C))),
      ],
    );
  }

  String _buildHtml() {
    return '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no"/>
<link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css"/>
<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
<style>
*{margin:0;padding:0;box-sizing:border-box}
html,body{width:100%;height:100%;font-family:system-ui,-apple-system,sans-serif}
#map{width:100%;height:100%;display:none}
#picker{width:100%;height:100%;background:#1E1E2E;display:flex;flex-direction:column;
  align-items:center;justify-content:center;padding:24px}
#picker h2{color:#fff;font-size:18px;margin-bottom:24px;font-weight:700}
.pick-btn{width:85%;max-width:320px;margin:6px 0;padding:14px 20px;border:none;border-radius:14px;
  font-size:15px;font-weight:700;color:#fff;cursor:pointer;display:flex;align-items:center;
  gap:12px;transition:transform 0.15s,opacity 0.15s}
.pick-btn:active{transform:scale(0.97);opacity:0.85}
.pick-dot{width:14px;height:14px;border-radius:50%;border:2px solid rgba(255,255,255,0.5);flex-shrink:0}
.pick-info{font-size:11px;font-weight:400;opacity:0.7;margin-left:auto}
.pick-all{background:linear-gradient(135deg,#E3051B,#006DB8,#00A651,#CE6BA4);margin-top:16px}

.station-label{font-size:10px;font-weight:600;white-space:nowrap;color:#222;
  text-shadow:0 0 3px #fff,0 0 3px #fff}
.loc-btn{position:absolute;top:12px;right:12px;z-index:999;width:40px;height:40px;
  border-radius:20px;background:rgba(30,30,46,0.9);border:none;color:#fff;font-size:20px;
  cursor:pointer;display:flex;align-items:center;justify-content:center;
  box-shadow:0 2px 8px rgba(0,0,0,0.3)}
.back-btn{position:absolute;bottom:16px;left:50%;transform:translateX(-50%);z-index:999;
  padding:10px 24px;border-radius:24px;background:rgba(30,30,46,0.92);border:none;
  color:#fff;font-size:13px;font-weight:600;cursor:pointer;
  box-shadow:0 2px 10px rgba(0,0,0,0.3);display:flex;align-items:center;gap:6px}
</style>
</head>
<body>

<div id="picker">
  <h2>Se deplacer</h2>
</div>

<div id="map"></div>
<button class="loc-btn" id="locBtn" style="display:none" onclick="requestLocation()">📍</button>
<button class="back-btn" id="backBtn" style="display:none" onclick="showPicker()">← Choisir une ligne</button>

<script>
var map;
var mapReady = false;

var lines = {
  'Ligne A':{color:'#E3051B',icon:'🚇',stations:[
    {name:'Basso Cambo',lat:43.5692,lng:1.3917},
    {name:'Bellefontaine',lat:43.5731,lng:1.3968},
    {name:'Reynerie',lat:43.5779,lng:1.4018},
    {name:'Mirail-Universite',lat:43.5798,lng:1.4063},
    {name:'Bagatelle',lat:43.5836,lng:1.4120},
    {name:'Mermoz',lat:43.5870,lng:1.4163},
    {name:'Fontaine Lestang',lat:43.5914,lng:1.4225},
    {name:'Arenes',lat:43.5956,lng:1.4260},
    {name:'Patte d\\'Oie',lat:43.5963,lng:1.4310},
    {name:'St-Cyprien-Republique',lat:43.5990,lng:1.4348},
    {name:'Esquirol',lat:43.6008,lng:1.4430},
    {name:'Capitole',lat:43.6042,lng:1.4439},
    {name:'Jean Jaures',lat:43.6060,lng:1.4490},
    {name:'Marengo-SNCF',lat:43.6110,lng:1.4540},
    {name:'Jolimont',lat:43.6110,lng:1.4614},
    {name:'Roseraie',lat:43.6090,lng:1.4692},
    {name:'Argoulets',lat:43.6080,lng:1.4771},
    {name:'Balma-Gramont',lat:43.6088,lng:1.4859}
  ]},
  'Ligne B':{color:'#006DB8',icon:'🚇',stations:[
    {name:'Borderouge',lat:43.6415,lng:1.4530},
    {name:'Trois Cocus',lat:43.6365,lng:1.4520},
    {name:'La Vache',lat:43.6310,lng:1.4498},
    {name:'Barriere de Paris',lat:43.6256,lng:1.4467},
    {name:'Minimes-C.Ader',lat:43.6215,lng:1.4467},
    {name:'Canal du Midi',lat:43.6170,lng:1.4456},
    {name:'Compans-Caffarelli',lat:43.6120,lng:1.4432},
    {name:'Jeanne d\\'Arc',lat:43.6090,lng:1.4450},
    {name:'Jean Jaures',lat:43.6060,lng:1.4490},
    {name:'F.Verdier',lat:43.6030,lng:1.4508},
    {name:'Carmes',lat:43.5992,lng:1.4462},
    {name:'Palais de Justice',lat:43.5970,lng:1.4410},
    {name:'St-Michel-M.Niel',lat:43.5925,lng:1.4400},
    {name:'Empalot',lat:43.5856,lng:1.4430},
    {name:'Saint-Agne-SNCF',lat:43.5790,lng:1.4450},
    {name:'Saouzelong',lat:43.5733,lng:1.4486},
    {name:'Faculte de Pharmacie',lat:43.5670,lng:1.4510},
    {name:'Universite P.Sabatier',lat:43.5615,lng:1.4626},
    {name:'Ramonville',lat:43.5568,lng:1.4735}
  ]},
  'Tramway T1':{color:'#00A651',icon:'🚊',stations:[
    {name:'Arenes',lat:43.5956,lng:1.4260},
    {name:'Casselardit',lat:43.5993,lng:1.4173},
    {name:'Fondeyre',lat:43.6025,lng:1.4110},
    {name:'Ancely',lat:43.6050,lng:1.4055},
    {name:'Cartoucherie',lat:43.6070,lng:1.4007},
    {name:'Zenith',lat:43.6100,lng:1.3950},
    {name:'Aeroconstellation',lat:43.6275,lng:1.3715},
    {name:'Beauzelle',lat:43.6505,lng:1.3642},
    {name:'Blagnac Gare SNCF',lat:43.6370,lng:1.3820}
  ]},
  'Tramway T2':{color:'#CE6BA4',icon:'🚊',stations:[
    {name:'Palais de Justice',lat:43.5970,lng:1.4410},
    {name:'St-Michel-M.Niel',lat:43.5925,lng:1.4400},
    {name:'Le TOEC',lat:43.5945,lng:1.4120},
    {name:'Lardenne',lat:43.5930,lng:1.3960},
    {name:'Ramassiers',lat:43.5920,lng:1.3820},
    {name:'Aeroport Toulouse-Blagnac',lat:43.6290,lng:1.3680}
  ]}
};

// Build picker buttons
var pickerEl = document.getElementById('picker');
Object.keys(lines).forEach(function(name){
  var line = lines[name];
  var btn = document.createElement('button');
  btn.className = 'pick-btn';
  btn.style.background = line.color;
  btn.innerHTML = '<span class="pick-dot" style="background:'+line.color+'"></span>'
    + line.icon + ' ' + name
    + '<span class="pick-info">'+line.stations.length+' stations</span>';
  btn.onclick = function(){ showLine(name); };
  pickerEl.appendChild(btn);
});
var allBtn = document.createElement('button');
allBtn.className = 'pick-btn pick-all';
allBtn.innerHTML = '🗺 Toutes les lignes';
allBtn.onclick = function(){ showLine(null); };
pickerEl.appendChild(allBtn);

function initMap(){
  if(mapReady) return;
  map = L.map('map',{zoomControl:false}).setView([43.6047,1.4442],13);
  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',{
    maxZoom:18,attribution:'OSM',referrerPolicy:'origin'
  }).addTo(map);
  mapReady = true;
}

var currentLayers = [];

function clearMap(){
  currentLayers.forEach(function(l){map.removeLayer(l)});
  currentLayers = [];
}

function drawLine(name){
  var line = lines[name];
  var coords = line.stations.map(function(s){return [s.lat,s.lng]});
  var polyline = L.polyline(coords,{color:line.color,weight:5,opacity:0.85}).addTo(map);
  currentLayers.push(polyline);

  line.stations.forEach(function(s){
    var m = L.circleMarker([s.lat,s.lng],{
      radius:7,fillColor:line.color,color:'#fff',weight:2.5,fillOpacity:1
    }).addTo(map);
    var tooltip = L.tooltip({permanent:true,direction:'top',offset:[0,-10],
      className:'station-label',opacity:1});
    tooltip.setContent(s.name);
    m.bindTooltip(tooltip);
    m.bindPopup('<b>'+s.name+'</b><br><span style="color:'+line.color+'">'+name+'</span>');
    currentLayers.push(m);
  });
}

function showLine(name){
  initMap();
  clearMap();
  document.getElementById('picker').style.display = 'none';
  document.getElementById('map').style.display = 'block';
  document.getElementById('locBtn').style.display = 'flex';
  document.getElementById('backBtn').style.display = 'flex';

  if(name === null){
    // Toutes les lignes
    Object.keys(lines).forEach(function(n){ drawLine(n); });
    map.setView([43.6047,1.4442],13);
  } else {
    drawLine(name);
    var line = lines[name];
    var bounds = L.latLngBounds(line.stations.map(function(s){return [s.lat,s.lng]}));
    map.fitBounds(bounds,{padding:[40,40]});
  }

  setTimeout(function(){map.invalidateSize()},100);
}

function showPicker(){
  clearMap();
  document.getElementById('map').style.display = 'none';
  document.getElementById('locBtn').style.display = 'none';
  document.getElementById('backBtn').style.display = 'none';
  document.getElementById('picker').style.display = 'flex';
}

var userMarker = null;
function requestLocation(){FlutterLocation.postMessage('getLocation')}
function onLocationSuccess(lat,lng){
  if(userMarker) map.removeLayer(userMarker);
  userMarker = L.marker([lat,lng],{
    icon:L.divIcon({html:'<div style="width:14px;height:14px;background:#4285F4;border:3px solid #fff;border-radius:50%;box-shadow:0 0 6px rgba(66,133,244,0.6)"></div>',
    iconSize:[14,14],iconAnchor:[7,7],className:''})
  }).addTo(map);
  map.setView([lat,lng],15);
}
</script>
</body>
</html>
''';
  }
}
