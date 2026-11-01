/*
 * Copyright 2022 Google LLC
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

#ifndef CPP_CAM_CAM_H_
#define CPP_CAM_CAM_H_

#include "cpp/cam/viewing_conditions.h"
#include "cpp/utils/utils.h"

namespace material_color_utilities {

struct Cam {
  double hue = 0.0;
  double chroma = 0.0;
  double j = 0.0;
  double q = 0.0;
  double m = 0.0;
  double s = 0.0;

  double jstar = 0.0;
  double astar = 0.0;
  double bstar = 0.0;
};

Cam CamFromInt(Argb argb);
Cam CamFromIntAndViewingConditions(Argb argb,
                                   const ViewingConditions &viewing_conditions);
Argb IntFromHcl(double hue, double chroma, double lstar);
Argb IntFromCam(Cam cam);
Cam CamFromUcsAndViewingConditions(double jstar, double astar, double bstar,
                                   const ViewingConditions &viewing_conditions);
/**
 * Given color expressed in the XYZ color space and viewed
 * in [viewingConditions], converts the color to CAM16.
 */
Cam CamFromXyzAndViewingConditions(double x, double y, double z,
                                   const ViewingConditions &viewing_conditions);

}  // namespace material_color_utilities
#endif  // CPP_CAM_CAM_H_
