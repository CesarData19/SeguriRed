import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  PlatformDispatcher.instance.onPlatformBrightnessChanged = () {};
  runApp(DenunciasApp());
}

class DenunciasApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App de Denuncias Anónimas',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: InicioScreen(),
    );
  }
}

class Denuncia {
  final String direccion;
  final String tipo;
  final LatLng posicion;

  Denuncia({required this.direccion, required this.tipo, required this.posicion});
}

List<Denuncia> denuncias = [];

class InicioScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          child: Text('Empezar'),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => MapaYDenunciasScreen()),
            );
          },
        ),
      ),
    );
  }
}

class MapaYDenunciasScreen extends StatefulWidget {
  @override
  _MapaYDenunciasScreenState createState() => _MapaYDenunciasScreenState();
}

class _MapaYDenunciasScreenState extends State<MapaYDenunciasScreen> {
  GoogleMapController? _mapController;

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final markers = denuncias.map((d) => Marker(
      markerId: MarkerId(d.direccion),
      position: d.posicion,
      infoWindow: InfoWindow(title: d.tipo, snippet: d.direccion),
    )).toSet();

    return Scaffold(
      appBar: AppBar(
        title: Text('Denuncias'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => InicioScreen()),
            ),
            child: Text('Inicio', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () async {
              final resultado = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => RealizarDenunciaScreen()),
              );
              if (resultado == true) {
                setState(() {});
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.black,
            ),
            child: Text('Realizar denuncia'),
          ),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: GoogleMap(
              onMapCreated: (controller) => _mapController = controller,
              initialCameraPosition: CameraPosition(
                target: LatLng(-12.0464, -77.0428),
                zoom: 12,
              ),
              markers: markers,
            ),
          ),
          Expanded(
            flex: 1,
            child: denuncias.isNotEmpty
                ? ListView(
              children: denuncias.map((d) => ListTile(
                title: Text('Tipo: ${d.tipo}'),
                subtitle: Text('Dirección: ${d.direccion}'),
              )).toList(),
            )
                : Center(child: Text('No hay denuncias aún')),
          ),
        ],
      ),
    );
  }
}

class RealizarDenunciaScreen extends StatefulWidget {
  @override
  _RealizarDenunciaScreenState createState() => _RealizarDenunciaScreenState();
}

class _RealizarDenunciaScreenState extends State<RealizarDenunciaScreen> {
  final _tipoController = TextEditingController();
  final _descController = TextEditingController();
  String direccion = '';
  LatLng? posicion;

  @override
  void dispose() {
    _tipoController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Nueva Denuncia')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _tipoController, decoration: InputDecoration(labelText: 'Tipo de denuncia')),
            TextField(controller: _descController, decoration: InputDecoration(labelText: 'Descripción')),
            Row(
              children: [
                Expanded(child: Text('Dirección: $direccion')),
                ElevatedButton(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SeleccionarDireccionScreen()),
                    );
                    if (result != null) {
                      setState(() {
                        direccion = result['direccion'];
                        posicion = result['posicion'];
                      });
                    }
                  },
                  child: Text('Elegir dirección'),
                ),
              ],
            ),
            Spacer(),
            ElevatedButton(
              onPressed: () {
                if (direccion.isNotEmpty && posicion != null) {
                  denuncias.add(Denuncia(
                    direccion: direccion,
                    tipo: _tipoController.text,
                    posicion: posicion!,
                  ));
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => GraciasScreen()),
                        (route) => route.isFirst,
                  );
                }
              },
              child: Text('Enviar Denuncia'),
            ),
          ],
        ),
      ),
    );
  }
}

class SeleccionarDireccionScreen extends StatefulWidget {
  @override
  _SeleccionarDireccionScreenState createState() => _SeleccionarDireccionScreenState();
}

class _SeleccionarDireccionScreenState extends State<SeleccionarDireccionScreen> {
  GoogleMapController? _mapController;
  LatLng seleccion = LatLng(-12.0464, -77.0428);
  Marker? marcador;

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _actualizarSeleccion(LatLng pos) {
    setState(() {
      seleccion = pos;
      marcador = Marker(
        markerId: MarkerId("seleccion"),
        position: pos,
        infoWindow: InfoWindow(title: "Ubicación seleccionada"),
      );
    });
  }

  void _confirmarSeleccion() {
    Navigator.pop(context, {
      'direccion': 'Coordenadas: ${seleccion.latitude}, ${seleccion.longitude}',
      'posicion': seleccion,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Seleccionar Dirección')),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) => _mapController = controller,
            initialCameraPosition: CameraPosition(target: seleccion, zoom: 14),
            onTap: _actualizarSeleccion,
            markers: marcador != null ? {marcador!} : {},
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: ElevatedButton.icon(
              onPressed: _confirmarSeleccion,
              icon: Icon(Icons.check),
              label: Text('Confirmar Dirección'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GraciasScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Future.delayed(Duration(seconds: 2), () => Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => InicioScreen()),
          (route) => false,
    ));

    return Scaffold(
      body: Center(child: Text('Gracias por su denuncia', style: TextStyle(fontSize: 24))),
    );
  }
}
