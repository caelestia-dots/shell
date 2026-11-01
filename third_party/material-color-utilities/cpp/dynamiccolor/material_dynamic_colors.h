/*
 * Copyright 2023 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#ifndef CPP_DYNAMICCOLOR_MATERIAL_DYNAMIC_COLORS_H_
#define CPP_DYNAMICCOLOR_MATERIAL_DYNAMIC_COLORS_H_

#include "cpp/dynamiccolor/dynamic_color.h"

namespace material_color_utilities {

class MaterialDynamicColors {
 public:
  static DynamicColor PrimaryPaletteKeyColor();
  static DynamicColor SecondaryPaletteKeyColor();
  static DynamicColor TertiaryPaletteKeyColor();
  static DynamicColor NeutralPaletteKeyColor();
  static DynamicColor NeutralVariantPaletteKeyColor();
  static DynamicColor Background();
  static DynamicColor OnBackground();
  static DynamicColor Surface();
  static DynamicColor SurfaceDim();
  static DynamicColor SurfaceBright();
  static DynamicColor SurfaceContainerLowest();
  static DynamicColor SurfaceContainerLow();
  static DynamicColor SurfaceContainer();
  static DynamicColor SurfaceContainerHigh();
  static DynamicColor SurfaceContainerHighest();
  static DynamicColor OnSurface();
  static DynamicColor SurfaceVariant();
  static DynamicColor OnSurfaceVariant();
  static DynamicColor InverseSurface();
  static DynamicColor InverseOnSurface();
  static DynamicColor Outline();
  static DynamicColor OutlineVariant();
  static DynamicColor Shadow();
  static DynamicColor Scrim();
  static DynamicColor SurfaceTint();
  static DynamicColor Primary();
  static DynamicColor OnPrimary();
  static DynamicColor PrimaryContainer();
  static DynamicColor OnPrimaryContainer();
  static DynamicColor InversePrimary();
  static DynamicColor Secondary();
  static DynamicColor OnSecondary();
  static DynamicColor SecondaryContainer();
  static DynamicColor OnSecondaryContainer();
  static DynamicColor Tertiary();
  static DynamicColor OnTertiary();
  static DynamicColor TertiaryContainer();
  static DynamicColor OnTertiaryContainer();
  static DynamicColor Error();
  static DynamicColor OnError();
  static DynamicColor ErrorContainer();
  static DynamicColor OnErrorContainer();
  static DynamicColor PrimaryFixed();
  static DynamicColor PrimaryFixedDim();
  static DynamicColor OnPrimaryFixed();
  static DynamicColor OnPrimaryFixedVariant();
  static DynamicColor SecondaryFixed();
  static DynamicColor SecondaryFixedDim();
  static DynamicColor OnSecondaryFixed();
  static DynamicColor OnSecondaryFixedVariant();
  static DynamicColor TertiaryFixed();
  static DynamicColor TertiaryFixedDim();
  static DynamicColor OnTertiaryFixed();
  static DynamicColor OnTertiaryFixedVariant();
};

}  // namespace material_color_utilities

#endif  // CPP_DYNAMICCOLOR_MATERIAL_DYNAMIC_COLORS_H_
