import 'package:flutter_test/flutter_test.dart';
import 'package:koebelt_dash/scripts/imports.dart';

void main() {
  test('the top-level modules a script imports', () {
    const src = '''
from koebelt_dash_scripts import connect
from __future__ import annotations
import cv2, numpy as np
import torch.nn as nn
from ultralytics import YOLO
from . import helpers
from sklearn.cluster import KMeans

"""
import notreal
"""

def f():
    import scipy.signal

try:
    import onnxruntime
except ImportError:
    onnxruntime = None
''';
    expect(importedModules(src), {'cv2', 'numpy', 'torch', 'ultralytics', 'sklearn', 'scipy'});
  });

  test('what pip calls them', () {
    expect(pipNameFor('cv2'), 'opencv-python');
    expect(pipNameFor('sklearn'), 'scikit-learn');
    expect(pipNameFor('PIL'), 'pillow');
    expect(pipNameFor('torch'), 'torch');
    expect(pipNameFor('tflite_runtime'), 'tflite-runtime');
  });
}
