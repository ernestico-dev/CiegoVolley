import 'package:flutter/material.dart';

import '../../../matches/domain/match_action.dart';

/// Color estable por fundamento, para gráficas y leyendas.
Color actionColor(ColorScheme scheme, MatchAction action) {
  return switch (action) {
    MatchAction.serve => scheme.primary,
    MatchAction.attack => scheme.tertiary,
    MatchAction.defense => scheme.secondary,
    MatchAction.block => scheme.error,
  };
}
