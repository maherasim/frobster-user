import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:lottie/lottie.dart' as lottie;
import 'package:nb_utils/nb_utils.dart';
import '../../component/base_scaffold_widget.dart';
import '../../main.dart';
import '../../model/update_location_response.dart';
import '../../network/rest_apis.dart';

class TrackLocation extends StatefulWidget {
  final int bookingId;
  final bool isHandyman;

  const TrackLocation(
      {Key? key, required this.bookingId, required this.isHandyman})
      : super(key: key);

  @override
  State<TrackLocation> createState() => _TrackLocationState();
}

class _TrackLocationState extends State<TrackLocation>
    with WidgetsBindingObserver {
  static const double _worldZoom = 2.0;
  static const double _locationZoom = 15.0;
  gmaps.CameraPosition _initialLocation = gmaps.CameraPosition(
    target: gmaps.LatLng(0.0, 0.0),
    zoom: _worldZoom,
  );
  UpdateLocationResponse? providerLocation;
  gmaps.GoogleMapController? mapController;
  Set<gmaps.Marker> _markers = {};
  gmaps.BitmapDescriptor? customIcon;
  lottie.LottieComposition? _composition;
  int _frame = 0;
  Timer? _timer;
  List<Uint8List>? _frames;
  StreamSubscription<UpdateLocationResponse>? _locationSubscription;
  bool isLoading = false;

  /// Location comes from API: GET get-location?booking_id={bookingId}
  /// Response: { "data": { "latitude", "longitude", "datetime" }, "message" }
  /// "Location not available" when: API failed, or backend returned (0,0), or coords invalid.
  bool get _hasValidLocation {
    if (providerLocation == null) return false;
    final lat = providerLocation!.data.latitude;
    final lng = providerLocation!.data.longitude;
    return lat != 0.0 && lng != 0.0 &&
        lat >= -90 && lat <= 90 &&
        lng >= -180 && lng <= 180;
  }

  void _moveMapToLocation() {
    if (mapController == null || !_hasValidLocation) return;
    final lat = providerLocation!.data.latitude.toDouble();
    final lng = providerLocation!.data.longitude.toDouble();
    mapController!.animateCamera(gmaps.CameraUpdate.newCameraPosition(
      gmaps.CameraPosition(target: gmaps.LatLng(lat, lng), zoom: _locationZoom),
    ));
  }

  @override
  void initState() {
    super.initState();
    allLocation();
    WidgetsBinding.instance.addObserver(this);
  }

  allLocation() async {
    await _loadCustomIcon();
    await setLocationfuns();
    _startLocationUpdates();
  }

  //region Methods
  void _startLocationUpdates() {
    _locationSubscription = Stream.periodic(Duration(seconds: 30))
        .asyncMap((_) => setLocationfuns())
        .listen((location) async {
      setState(() {
        providerLocation = location;
      });
      _updateMarker();
      setState(() {
        isLoading = false;
      });
    });
  }

  Future<UpdateLocationResponse> setLocationfuns() async {
    setState(() {
      isLoading = true;
    });
    try {
      var value = await getProviderLocation(widget.bookingId);
      setState(() {
        providerLocation = value;
      });
      _updateMarker();
      return value;
    } catch (e) {
      log("Error ==> $e");
      setState(() {
        isLoading = false;
      });
      return UpdateLocationResponse(data: Data());
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadCustomIcon() async {
    _composition =
        await lottie.AssetLottie('assets/lottie/wave_indicator.json').load();
    if (_composition != null) {
      _frames = await _precacheFrames(_composition!, 100, 100);
      _startAnimation();
    }
  }

  void _startAnimation() {
    _timer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      if (_frames != null) {
        _updateMarkerWithFrame(_frame);
        _frame = (_frame + 1) % _frames!.length;
      }
    });
  }

  Future<List<Uint8List>> _precacheFrames(
      lottie.LottieComposition composition, int width, int height) async {
    List<Uint8List> frames = [];
    int frameCount = composition.durationFrames.toInt();

    for (int i = 0; i < frameCount; i++) {
      final frameData = await _captureLottieFrameAsImage(i, width, height);
      frames.add(frameData);
    }

    return frames;
  }

  Future<void> _updateMarkerWithFrame(int frame) async {
    if (_frames == null) return;

    final iconBytes = _frames![frame];
    customIcon = gmaps.BitmapDescriptor.fromBytes(iconBytes);
    _updateMarker();
  }

  Future<Uint8List> _captureLottieFrameAsImage(
      int frame, int width, int height) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final drawable = lottie.LottieDrawable(_composition!);
    drawable.setProgress(frame / _composition!.durationFrames);
    drawable.draw(
        canvas, Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));

    final picture = recorder.endRecording();
    final img = await picture.toImage(width, height);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }

  void _updateMarker() {
    if (providerLocation == null) return;
    if (!_hasValidLocation) {
      setState(() => _markers = {});
      return;
    }
    final lat = providerLocation!.data.latitude.toDouble();
    final lng = providerLocation!.data.longitude.toDouble();
    log("Updating marker: Lat=$lat, Lng=$lng");
    setState(() {
      _markers = {
        gmaps.Marker(
          markerId: gmaps.MarkerId('providerLocation'),
          position: gmaps.LatLng(lat, lng),
          icon: customIcon ?? gmaps.BitmapDescriptor.defaultMarker,
        ),
      };
    });
    _moveMapToLocation();
  }

  void stopProviderLocation() {
    _timer?.cancel();
    _locationSubscription?.cancel();
    mapController?.dispose();
  }
  //endregion

  //region Closing
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      stopProviderLocation();
    } else if (state == AppLifecycleState.resumed) {
      setLocationfuns();
      _startLocationUpdates();
    }
  }

  @override
  void dispose() {
    stopProviderLocation();
    super.dispose();
  }

  //endregion closing

  @override
  Widget build(BuildContext context) {
    final initialTarget = _hasValidLocation
        ? gmaps.LatLng(
            providerLocation!.data.latitude.toDouble(),
            providerLocation!.data.longitude.toDouble(),
          )
        : gmaps.LatLng(0.0, 0.0);
    final initialZoom = _hasValidLocation ? _locationZoom : _worldZoom;

    return AppScaffold(
      appBarTitle: widget.isHandyman
          ? language.trackHandymanLocation
          : language.trackProviderLocation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_hasValidLocation &&
              providerLocation!.data.datetime.toString().trim().isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    '${language.lastUpdatedAt} ',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  Expanded(
                    child: Text(
                      DateTime.tryParse(
                                  providerLocation!.data.datetime.toString()) !=
                              null
                          ? (DateTime.parse(
                                  providerLocation!.data.datetime.toString())
                              .timeAgo)
                          : providerLocation!.data.datetime.toString(),
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Stack(
              children: [
                gmaps.GoogleMap(
            mapType: gmaps.MapType.normal,
            zoomGesturesEnabled: true,
            zoomControlsEnabled: true,
            markers: _markers,
            initialCameraPosition: gmaps.CameraPosition(
              target: initialTarget,
              zoom: initialZoom,
            ),
            gestureRecognizers: Set()
              ..add(Factory<OneSequenceGestureRecognizer>(
                  () => new EagerGestureRecognizer()))
              ..add(Factory<PanGestureRecognizer>(() => PanGestureRecognizer()))
              ..add(Factory<ScaleGestureRecognizer>(
                  () => ScaleGestureRecognizer()))
              ..add(Factory<TapGestureRecognizer>(() => TapGestureRecognizer()))
              ..add(Factory<VerticalDragGestureRecognizer>(
                  () => VerticalDragGestureRecognizer())),
            onMapCreated: (controller) {
              mapController = controller;
              if (_hasValidLocation) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _moveMapToLocation();
                });
              }
            },
          ),
          Positioned(
            left: 10,
            top: 10,
            child: CupertinoActivityIndicator(color: black).visible(isLoading),
          ),
          if (!_hasValidLocation && !isLoading)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                color: Colors.black54,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Location not available. Worker may not have shared location yet, or the request failed. Tap refresh to try again.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    8.height,
                    Material(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        onTap: () => setLocationfuns(),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.refresh, color: Colors.white, size: 20),
                              8.width,
                              Text(
                                'Refresh location',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
