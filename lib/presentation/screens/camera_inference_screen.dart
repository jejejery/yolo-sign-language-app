// Ultralytics 🚀 AGPL-3.0 License - https://ultralytics.com/license

import 'package:flutter/material.dart';
import 'package:ultralytics_yolo/yolo_result.dart';
import 'package:ultralytics_yolo/yolo_view.dart';
import 'package:ultralytics_yolo/yolo_task.dart';
import '../../models/model_type.dart';
import '../../models/slider_type.dart';
import '../../services/model_manager.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
// stream subscriptions import 
import 'dart:async';

/// A screen that demonstrates real-time YOLO inference using the device camera.
///
/// This screen provides:
/// - Live camera feed with YOLO object detection
/// - Model selection (detect, segment, classify, pose, obb)
/// - Adjustable thresholds (confidence, IoU, max detections)
/// - Camera controls (flip, zoom)
/// - Performance metrics (FPS)
class CameraInferenceScreen extends StatefulWidget {
  const CameraInferenceScreen({super.key});

  @override
  State<CameraInferenceScreen> createState() => _CameraInferenceScreenState();
}

class _CameraInferenceScreenState extends State<CameraInferenceScreen> {
  int _detectionCount = 0;
  double _confidenceThreshold = 0.5;
  double _iouThreshold = 0.45;
  int _numItemsThreshold = 30;
  double _currentFps = 0.0;
  int _frameCount = 0;
  DateTime _lastFpsUpdate = DateTime.now();

  SliderType _activeSlider = SliderType.none;
  String _modelName = modelNames.first;
  ModelType _selectedModel = ModelType(modelNames.first, YOLOTask.detect);
  bool _isModelLoading = false;
  String? _modelPath;
  String _loadingMessage = '';
  double _downloadProgress = 0.0;
  double _currentZoomLevel = 1.0;
  bool _isFrontCamera = false;
  String _detectionResult = '';
  bool _isKeyboardVisible = false;
  late StreamSubscription<bool> keyboardSubscription;

   final TextEditingController _detectionController = TextEditingController();

  final _yoloController = YOLOViewController();
  final _yoloViewKey = GlobalKey<YOLOViewState>();
  final bool _useController = true;

  late final ModelManager _modelManager;

  @override
  void initState() {
    super.initState();

    keyboardSubscription = KeyboardVisibilityController().onChange.listen((bool visible) {
    setState(() {
      _isKeyboardVisible = visible;
    });
  });

    // Initialize ModelManager
    _modelManager = ModelManager(
      onDownloadProgress: (progress) {
        if (mounted) {
          setState(() {
            _downloadProgress = progress;
          });
        }
      },
      onStatusUpdate: (message) {
        if (mounted) {
          setState(() {
            _loadingMessage = message;
          });
        }
      },
    );

    // Load initial model
    _loadModelForPlatform();

    // Set initial thresholds after frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_useController) {
        _yoloController.setThresholds(
          confidenceThreshold: _confidenceThreshold,
          iouThreshold: _iouThreshold,
          numItemsThreshold: _numItemsThreshold,
        );
      } else {
        _yoloViewKey.currentState?.setThresholds(
          confidenceThreshold: _confidenceThreshold,
          iouThreshold: _iouThreshold,
          numItemsThreshold: _numItemsThreshold,
        );
      }
    });
  }

  @override
  void dispose() {

    keyboardSubscription.cancel();
    super.dispose();
  }

  /// Called when new detection results are available
  ///
  /// Updates the UI with:
  /// - Number of detections
  /// - FPS calculation
  /// - Debug information for first few detections
  void _onDetectionResults(List<YOLOResult> results) {
    if (!mounted) return;

    _frameCount++;
    final now = DateTime.now();
    final elapsed = now.difference(_lastFpsUpdate).inMilliseconds;

    if (elapsed >= 1000) {
      final calculatedFps = _frameCount * 1000 / elapsed;
      debugPrint('Calculated FPS: ${calculatedFps.toStringAsFixed(1)}');

      _currentFps = calculatedFps;
      _frameCount = 0;
      _lastFpsUpdate = now;

       
        setState(() {
          // update detection results
          _detectionResult = results.isEmpty ?  '' : '${results[0].className}';
        });
      
    }

    // Still update detection count in the UI
    setState(() {
      _detectionCount = results.length;
    });

    // Debug first few detections
    for (var i = 0; i < results.length && i < 3; i++) {
      final r = results[i];
      debugPrint(
        'Detection $i: ${r.className} (${(r.confidence * 100).toStringAsFixed(1)}%) at ${r.boundingBox}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // YOLO View: must be at back
          if (_modelPath != null && !_isModelLoading)
            Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: _isKeyboardVisible ? 40 : 10),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        // Calculate available height minus some padding for nav bar
                        final availableHeight = MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - 80;
                        return SizedBox(
                          width: screenWidth * 0.9,
                          height: availableHeight * 0.9,
                          child: YOLOView(
                            key: _useController
                                ? const ValueKey('yolo_view_static')
                                : _yoloViewKey,
                            controller: _useController ? _yoloController : null,
                            modelPath: _modelPath!,
                            task: _selectedModel.task,
                            onResult: _onDetectionResults,
                            onPerformanceMetrics: (metrics) {
                              if (mounted) {
                                setState(() {
                                  if (metrics['fps'] != null) {
                                    _currentFps = metrics['fps']!;
                                  }
                                });
                              }
                            },
                            onZoomChanged: (zoomLevel) {
                              if (mounted) {
                                setState(() {
                                  _currentZoomLevel = zoomLevel;
                                });
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            )
          else if (_isModelLoading)
            IgnorePointer(
              child: Container(
                color: Colors.black87,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 32),
                      // Loading message
                      Text(
                        _loadingMessage,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      // Progress indicator
                      if (_downloadProgress > 0)
                        Column(
                          children: [
                            SizedBox(
                              width: 200,
                              child: LinearProgressIndicator(
                                value: _downloadProgress,
                                backgroundColor: Colors.white24,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                                minHeight: 4,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${(_downloadProgress * 100).toInt()}%',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        )
                      else
                        const CircularProgressIndicator(color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),

          // Top info pills (detection, FPS, and current threshold)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16, // Safe area + spacing
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Model selector
                _buildModelSelector(),
                const SizedBox(height: 12),
                IgnorePointer(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'DETECTIONS: $_detectionCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'FPS: ${_currentFps.toStringAsFixed(1)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                if (_activeSlider == SliderType.confidence)
                  _buildTopPill(
                    'CONFIDENCE THRESHOLD: ${_confidenceThreshold.toStringAsFixed(2)}',
                  ),
                if (_activeSlider == SliderType.iou)
                  _buildTopPill(
                    'IOU THRESHOLD: ${_iouThreshold.toStringAsFixed(2)}',
                  ),
                if (_activeSlider == SliderType.numItems)
                  _buildTopPill('ITEMS MAX: $_numItemsThreshold'),
                const SizedBox(height: 300),
                // Detection result text field
                Row(
                  children: [
                    // TextFormField dengan ukuran yang lebih kecil
                    Container(
                      width: 300, // Tentukan lebar yang diinginkan untuk TextFormField
                      child: TextFormField(
                        controller: _detectionController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Colors.black54,
                              width: 1.0,
                            ),
                          ),
                          hintText: 'Text Result',
                        ),
                        style: const TextStyle(color: Colors.black),
                        cursorColor: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 8), // Memberikan jarak antara TextFormField dan CircleAvatar
                    // CircleAvatar dengan ikon
                    CircleAvatar(
                      radius: 20, // Ukuran lingkaran yang kecil
                      backgroundColor: Colors.lightBlueAccent.withOpacity(0.8),
                      child: IconButton(
                        icon: const Icon(Icons.camera_outlined, color: Colors.white),
                        onPressed: () {
                          // Menambahkan deteksi hasil ke dalam TextFormField
                          if (_detectionResult != '') {
                            _detectionController.text += _detectionResult;
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16), // Spacing between top pills and controls
                Row( 
                  mainAxisAlignment: MainAxisAlignment.center, 
                  children: [
                  _buildCircleButton(
                    '${_currentZoomLevel.toStringAsFixed(1)}x',
                    'Zoom',
                    onPressed: () {
                      // Cycle through zoom levels: 0.5x -> 1.0x -> 3.0x -> 0.5x
                      double nextZoom;
                      if (_currentZoomLevel < 0.75) {
                        nextZoom = 1.0;
                      } else if (_currentZoomLevel < 2.0) {
                        nextZoom = 3.0;
                      } else {
                        nextZoom = 0.5;
                      }
                      _setZoomLevel(nextZoom);
                    },
                  ),
                  const SizedBox(width: 76),
                 _buildIconButton(Icons.layers, 
                 'Max Detections',
                 () {
                  _toggleSlider(SliderType.numItems);
                }, fontSize: 8),
                ],
                ),
                const SizedBox(height: 16), // Spacing between coluumns
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildIconButton(Icons.adjust, 
                    'Confidence',
                    () {
                      _toggleSlider(SliderType.confidence);
                    }),
                    const SizedBox(width: 64),
                    _buildIconButton('assets/iou.png', 
                    'IoU',
                    () {
                      _toggleSlider(SliderType.iou);
                    }),
                  ],
                ),
              ],
            ),
          ),


          // Bottom slider overlay
          if (_activeSlider != SliderType.none)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                color: Colors.black.withOpacity(0.8),
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.yellow,
                    inactiveTrackColor: Colors.white.withOpacity(0.3),
                    thumbColor: Colors.yellow,
                    overlayColor: Colors.yellow.withOpacity(0.2),
                  ),
                  child: Slider(
                    value: _getSliderValue(),
                    min: _getSliderMin(),
                    max: _getSliderMax(),
                    divisions: _getSliderDivisions(),
                    label: _getSliderLabel(),
                    onChanged: (value) {
                      setState(() {
                        _updateSliderValue(value);
                      });
                    },
                  ),
                ),
              ),
            ),
          // Camera flip top-right
        if(!_isKeyboardVisible)
         Positioned(
            bottom: 16, // Adjust 320 to your needs
            left: 16,
            child: SafeArea(
              child: CircleAvatar(
                radius: 24,
                backgroundColor: Colors.black.withOpacity(0.5),
                child: IconButton(
                  icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _isFrontCamera = !_isFrontCamera;
                      // Reset zoom level when switching to front camera
                      if (_isFrontCamera) {
                        _currentZoomLevel = 1.0;
                      }
                    });
                    if (_useController) {
                      _yoloController.switchCamera();
                    } else {
                      _yoloViewKey.currentState?.switchCamera();
                    }
                  },
                ),
              ), 
            )
          ),
        ],
      ),
    );
  }

  /// Builds a circular button with an icon or image
  ///
  /// [iconOrAsset] can be either an IconData or an asset path string
  /// [onPressed] is called when the button is tapped
  Widget _buildIconButton(
  dynamic iconOrAsset,
  String name,
  VoidCallback onPressed, {
  double fontSize = 12,
  double width = 72, // Set a fixed width for button+label
}) {
  return SizedBox(
    width: width,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: const Color.fromARGB(255, 75, 167, 241),
          child: IconButton(
            icon: iconOrAsset is IconData
                ? Icon(iconOrAsset, color: Colors.white)
                : Image.asset(
                    iconOrAsset,
                    width: 24,
                    height: 24,
                    color: Colors.white,
                  ),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.black,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

  /// Builds a circular button with text
  ///
  /// [label] is the text to display in the button
  /// [onPressed] is called when the button is tapped
  Widget _buildCircleButton(String label, String name, {required VoidCallback onPressed}) {
    return Column(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: const Color.fromARGB(255, 75, 167, 241),
          child: TextButton(
            onPressed: onPressed,
            child: Text(label, style: const TextStyle(color: Colors.white)),
          ),
        ),
        const SizedBox(height: 8), // Spacing between button and label
        Text(
          name,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Toggles the active slider type
  ///
  /// If the same slider type is selected again, it will be hidden.
  /// Otherwise, the new slider type will be shown.
  void _toggleSlider(SliderType type) {
    setState(() {
      _activeSlider = (_activeSlider == type) ? SliderType.none : type;
    });
  }

  /// Builds a pill-shaped container with text
  ///
  /// [label] is the text to display in the pill
  Widget _buildTopPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Gets the current value for the active slider
  double _getSliderValue() {
    switch (_activeSlider) {
      case SliderType.numItems:
        return _numItemsThreshold.toDouble();
      case SliderType.confidence:
        return _confidenceThreshold;
      case SliderType.iou:
        return _iouThreshold;
      default:
        return 0;
    }
  }

  /// Gets the minimum value for the active slider
  double _getSliderMin() => _activeSlider == SliderType.numItems ? 5 : 0.1;

  /// Gets the maximum value for the active slider
  double _getSliderMax() => _activeSlider == SliderType.numItems ? 50 : 0.9;

  /// Gets the number of divisions for the active slider
  int _getSliderDivisions() => _activeSlider == SliderType.numItems ? 9 : 8;

  /// Gets the label text for the active slider
  String _getSliderLabel() {
    switch (_activeSlider) {
      case SliderType.numItems:
        return '$_numItemsThreshold';
      case SliderType.confidence:
        return _confidenceThreshold.toStringAsFixed(1);
      case SliderType.iou:
        return _iouThreshold.toStringAsFixed(1);
      default:
        return '';
    }
  }

  /// Updates the value of the active slider
  ///
  /// This method updates both the UI state and the YOLO view controller
  /// with the new threshold value.
  void _updateSliderValue(double value) {
    switch (_activeSlider) {
      case SliderType.numItems:
        _numItemsThreshold = value.toInt();
        if (_useController) {
          _yoloController.setNumItemsThreshold(_numItemsThreshold);
        } else {
          _yoloViewKey.currentState?.setNumItemsThreshold(_numItemsThreshold);
        }
        break;
      case SliderType.confidence:
        _confidenceThreshold = value;
        if (_useController) {
          _yoloController.setConfidenceThreshold(value);
        } else {
          _yoloViewKey.currentState?.setConfidenceThreshold(value);
        }
        break;
      case SliderType.iou:
        _iouThreshold = value;
        if (_useController) {
          _yoloController.setIoUThreshold(value);
        } else {
          _yoloViewKey.currentState?.setIoUThreshold(value);
        }
        break;
      default:
        break;
    }
  }

  /// Sets the camera zoom level
  ///
  /// Updates both the UI state and the YOLO view controller with the new zoom level.
  void _setZoomLevel(double zoomLevel) {
    setState(() {
      _currentZoomLevel = zoomLevel;
    });
    if (_useController) {
      _yoloController.setZoomLevel(zoomLevel);
    } else {
      _yoloViewKey.currentState?.setZoomLevel(zoomLevel);
    }
  }

  /// Builds the model selector widget
  ///
  /// Creates a row of buttons for selecting different YOLO model types.
  /// Each button shows the model type name and highlights the selected model.
  Widget _buildModelSelector() {
    return Container(
      height: 36,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      // if (!_isModelLoading && model != _selectedModel) {
      //           setState(() {
      //             _selectedModel = model;
      //           });
      //           _loadModelForPlatform();
      //         }
      child: GestureDetector(
              onTap: () {
                // implement show modal
                showModal();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color:  Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _modelName.toUpperCase(),
                  style: const TextStyle(
                    color:Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
      // Row(
      //   mainAxisSize: MainAxisSize.min,
      //   children: modelTypes.map((model) {
      //     final isSelected = _selectedModel == model;
      //     return GestureDetector(
      //       onTap: () {
      //         // implement show modal
      //       },
      //       child: Container(
      //         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      //         decoration: BoxDecoration(
      //           color: isSelected ? Colors.white : Colors.transparent,
      //           borderRadius: BorderRadius.circular(6),
      //         ),
      //         child: Text(
      //           model.modelName.toUpperCase(),
      //           style: TextStyle(
      //             color: isSelected ? Colors.black : Colors.white,
      //             fontSize: 12,
      //             fontWeight: FontWeight.w600,
      //           ),
      //         ),
      //       ),
      //     );
      //   }).toList(),
      // ),
    );
  }

  Future<void> showModal() async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.5, // 50% tinggi layar
        minChildSize: 0.5,
        maxChildSize: 0.75,    // Bisa ditarik hingga 75%
        expand: false,
        builder: (context, scrollController) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: ListView.builder(
              controller: scrollController,
              itemCount: modelNames.length,
              itemBuilder: (context, index) {
                final model = modelNames[index];
                final isSelected = _selectedModel.modelName == model;
                return ListTile(
                  title: Text(model.toUpperCase()),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedModel = ModelType(model, YOLOTask.detect);
                      _modelName = model;
                    });
                    _loadModelForPlatform();
                  },
                );
              },
            ),
          );
        },
      );
    },
  );
}


  Future<void> _loadModelForPlatform() async {
    setState(() {
      _isModelLoading = true;
      _loadingMessage = 'Loading ${_selectedModel.modelName} model...';
      _downloadProgress = 0.0;
      // Reset metrics when switching models
      _detectionCount = 0;
      _currentFps = 0.0;
      _frameCount = 0;
      _lastFpsUpdate = DateTime.now();
    });

    try {
      // Use ModelManager to get the model path
      // This will automatically download if not found locally
      final modelPath = await _modelManager.getModelPath(_selectedModel);

      if (mounted) {
        setState(() {
          _modelPath = modelPath;
          _isModelLoading = false;
          _loadingMessage = '';
          _downloadProgress = 0.0;
        });

        if (modelPath != null) {
          debugPrint('CameraInferenceScreen: Model path set to: $modelPath');
        } else {
          // Model loading failed
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Model Not Available'),
              content: Text(
                'Failed to load ${_selectedModel.modelName} model. Please check your internet connection and try again.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error loading model: $e');
      if (mounted) {
        setState(() {
          _isModelLoading = false;
          _loadingMessage = 'Failed to load model';
          _downloadProgress = 0.0;
        });
        // Show error dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Model Loading Error'),
            content: Text(
              'Failed to load ${_selectedModel.modelName} model: ${e.toString()}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }
}
