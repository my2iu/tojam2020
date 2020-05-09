import 'dart:core';
import 'dart:math' as Math;

import 'dart:typed_data';
// package com.user00.my2iu.games.framework.geom;

// TODO: This is all a big mess as to whether it's column-major or row-major
// and whether the matrices are designed for left-multiplication or right-multiplication
// Use with caution!!


class Mat4
{
  List<double> data;
  Mat4(List<double> data)
  {
    this.data = data;
  }

  Mat4 transpose()
  {
      List<double> a = this.data;
      return new Mat4([a[0], a[4], a[8], a[12],
          a[1], a[5], a[9], a[13],
          a[2], a[6], a[10], a[14],
          a[3], a[7], a[11], a[15]
      ]);
  }

  static Mat4 I()
  {
    return new Mat4([1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1]);
  }

  static Mat4 fromWebXrFloat32Array(Float32List arr)
  {
    Mat4 toReturn = Mat4.I();
    for (int n = 0; n < 16; n++)
      toReturn.data[n] = arr[n];
    return toReturn;
  }

//Mat4.translate = function(x,y,z) {
//    return new Mat4([1,0,0,x, 0,1,0,y, 0,0,1,z, 0,0,0,1]).transpose();
//};
//Mat4.scale = function(sx,sy,sz) {
//    return new Mat4([sx,0,0,0, 0,sy,0,0, 0,0,sz,0, 0,0,0,1]).transpose();
//};
//Mat4.shearZ = function(dx, dy)
//{
//    return new Mat4(
//            [1, 0, dx, 0,
//             0, 1, dy, 0,
//             0, 0, 1, 0,
//             0, 0, 0, 1]).transpose();
//};
//Mat4.shearX = function(dy, dz)
//{
//    return new Mat4(
//            [1, 0, 0, 0,
//             dy, 1, 0, 0,
//             dz, 0, 1, 0,
//             0, 0, 0, 1]).transpose();
//};
//Mat4.shearY = function(dx, dz)
//{
//    return new Mat4(
//            [1, dx, 0, 0,
//             0, 1, 0, 0,
//             0, dz, 1, 0,
//             0, 0, 0, 1]).transpose();
//};
//Mat4.rotateZ = function(theta)
//{
//    return new Mat4([Math.cos(theta), -Math.sin(theta), 0, 0,
//        Math.sin(theta), Math.cos(theta), 0, 0,
//        0, 0, 1, 0,
//        0, 0, 0, 1]).transpose();
//};
//Mat4.rotateX = function(theta)
//{
//    return new Mat4([1, 0, 0, 0,
//        0, Math.cos(theta), -Math.sin(theta), 0,
//        0, Math.sin(theta), Math.cos(theta), 0,
//        0, 0, 0, 1]).transpose();
//};
//Mat4.rotateY = function(theta)
//{
//    return new Mat4([Math.cos(theta), 0, Math.sin(theta), 0,
//        0, 1, 0, 0,
//        -Math.sin(theta), 0, Math.cos(theta), 0,
//        0, 0, 0, 1]).transpose();
//};
 static Mat4 perspective (double viewAngle, double aspect, double near, double far)
{
    double directionMultiplier = 1;
    return new Mat4([1/(Math.tan(viewAngle / 2))/aspect, 0, 0, 0,
        0, 1/(Math.tan(viewAngle / 2)), 0, 0,
        0, 0, directionMultiplier * (far + near) / (far - near), -2 * far * near / (far - near),
        0, 0, directionMultiplier, 0]).transpose();
}

 Mat4 mul(Mat4 bb)
{
    List<double> a = bb.data;
    List<double> b = this.data;
    List<double> c = new List<double>(16);
    _googMultMat(b, a, c);
    return new Mat4(c);//.transpose();
}
 Mat4 clone()
{
    Mat4 toReturn = new Mat4(new List<double>(16));
    _googSetFromArray(toReturn.data, this.data);
    return toReturn;
}
 Mat4 scale(double sx, double sy, double sz)
{
    return this.clone().scaleThis(sx, sy, sz);
}
 Mat4 scaleThis(double sx,double sy,double sz)
{
    _googScale(this.data, sx, sy, sz);
    return this;
}
 Mat4 translate(double x, double y, double z)
{
    return this.clone().translateThis(x, y, z);
}
 Mat4 translateThis(double x,double y,double z)
{
    _googTranslate(this.data, x, y, z);
    return this;
}
//Mat4.prototype.rotateX = function(angle)
//{
//    return this.clone().rotateThis(angle, 1, 0, 0);
//};
//Mat4.prototype.rotateY = function(angle)
//{
//    return this.clone().rotateThis(angle, 0, 1, 0);
//};
//Mat4.prototype.rotateZ = function(angle)
//{
//    return this.clone().rotateThis(angle, 0, 0, 1);
//};
//Mat4.prototype.rotateXThis = function(angle)
//{
//    return this.rotateThis(angle, 1, 0, 0);
//};
//Mat4.prototype.rotateYThis = function(angle)
//{
//    return this.rotateThis(angle, 0, 1, 0);
//};
//Mat4.prototype.rotateZThis = function(angle)
//{
//    return this.rotateThis(angle, 0, 0, 1);
//};
//Mat4.prototype.rotateThis = function(angle, x, y, z)
//{
//    goog.vec.Mat4.rotate(this.data, angle, x, y, z);
//    return this;
//};
//Mat4.prototype.shearZ = function(dx, dy)
//{
//    return this.clone().shearZThis(dx, dy);
//};
//Mat4.prototype.shearZThis = function(dx, dy)
//{
//    var m = this.data;
//    goog.vec.Mat4.setColumnValues(this.data, 2, 
//            m[0] * dx + m[4] * dy + m[8],
//            m[1] * dx + m[5] * dy + m[9],
//            m[2] * dx + m[6] * dy + m[10],
//            m[3] * dx + m[7] * dy + m[11]);
//    return this;
//};
//// Creates a transformation matrix for normals, and turns that into
//// an array appropriate for loading into WebGL.
//Mat4.prototype.asNormalMatrixGLArray = function() {
//    // We want the inverse transpose of the upper 3x3 submatrix
//    
//    // We should transpose it first, but the WebGL format is
//    // already transposed to what we want, so we'll just take it
//    // raw
//
//    // Inversion formulae from Wikipedia
//    var a = this.data[0];
//    var b = this.data[1];
//    var c = this.data[2];
//    var d = this.data[4];
//    var e = this.data[5];
//    var f = this.data[6];
//    var g = this.data[8];
//    var h = this.data[9];
//    var k = this.data[10];
//
//    var detA = a * (e*k - f*h) + b * (f*g - k*d) + c * (d*h - e*g);
//    var A = e*k - f*h;
//    var B = f*g - d*k;
//    var C = d*h - e*g;
//    var D = c*h - b*k;
//    var E = a*k - c*g;
//    var F = g*b - a*h;
//    var G = b*f - c*e;
//    var H = c*d - a*f;
//    var K = a*e - b*d;
//    return [A/detA, B/detA, C/detA, D/detA, E/detA, F/detA, G/detA, H/detA, K/detA];
////  return [A, D, G, B, E, H, C, F, K];
//};
//Mat4.prototype.asGLArray = function() {
//    return this.data;
//};








//Code taken from Google's Closure library, version 20111110-r1376
//

//Copyright 2011 The Closure Library Authors. All Rights Reserved.
//
//Licensed under the Apache License, Version 2.0 (the "License");
//you may not use this file except in compliance with the License.
//You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
//Unless required by applicable law or agreed to in writing, software
//distributed under the License is distributed on an "AS-IS" BASIS,
//WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//See the License for the specific language governing permissions and
//limitations under the License.
   static void _googMultMat(List<double> mat0, List<double> mat1, List<double>resultMat)
  {
      double a00 = mat0[0], a10 = mat0[1], a20 = mat0[2], a30 = mat0[3];
      double a01 = mat0[4], a11 = mat0[5], a21 = mat0[6], a31 = mat0[7];
      double a02 = mat0[8], a12 = mat0[9], a22 = mat0[10], a32 = mat0[11];
      double a03 = mat0[12], a13 = mat0[13], a23 = mat0[14], a33 = mat0[15];

      double b00 = mat1[0], b10 = mat1[1], b20 = mat1[2], b30 = mat1[3];
      double b01 = mat1[4], b11 = mat1[5], b21 = mat1[6], b31 = mat1[7];
      double b02 = mat1[8], b12 = mat1[9], b22 = mat1[10], b32 = mat1[11];
      double b03 = mat1[12], b13 = mat1[13], b23 = mat1[14], b33 = mat1[15];

      resultMat[0] = a00 * b00 + a01 * b10 + a02 * b20 + a03 * b30;
      resultMat[1] = a10 * b00 + a11 * b10 + a12 * b20 + a13 * b30;
      resultMat[2] = a20 * b00 + a21 * b10 + a22 * b20 + a23 * b30;
      resultMat[3] = a30 * b00 + a31 * b10 + a32 * b20 + a33 * b30;

      resultMat[4] = a00 * b01 + a01 * b11 + a02 * b21 + a03 * b31;
      resultMat[5] = a10 * b01 + a11 * b11 + a12 * b21 + a13 * b31;
      resultMat[6] = a20 * b01 + a21 * b11 + a22 * b21 + a23 * b31;
      resultMat[7] = a30 * b01 + a31 * b11 + a32 * b21 + a33 * b31;

      resultMat[8] = a00 * b02 + a01 * b12 + a02 * b22 + a03 * b32;
      resultMat[9] = a10 * b02 + a11 * b12 + a12 * b22 + a13 * b32;
      resultMat[10] = a20 * b02 + a21 * b12 + a22 * b22 + a23 * b32;
      resultMat[11] = a30 * b02 + a31 * b12 + a32 * b22 + a33 * b32;

      resultMat[12] = a00 * b03 + a01 * b13 + a02 * b23 + a03 * b33;
      resultMat[13] = a10 * b03 + a11 * b13 + a12 * b23 + a13 * b33;
      resultMat[14] = a20 * b03 + a21 * b13 + a22 * b23 + a23 * b33;
      resultMat[15] = a30 * b03 + a31 * b13 + a32 * b23 + a33 * b33;
  }
  
   static void _googRotate(List<double>mat, double angle, double x, double y, double z) {
    double m00 = mat[0], m10 = mat[1], m20 = mat[2], m30 = mat[3];
    double m01 = mat[4], m11 = mat[5], m21 = mat[6], m31 = mat[7];
    double m02 = mat[8], m12 = mat[9], m22 = mat[10], m32 = mat[11];
    double m03 = mat[12], m13 = mat[13], m23 = mat[14], m33 = mat[15];

    double cosAngle = Math.cos(angle);
    double sinAngle = Math.sin(angle);
    double diffCosAngle = 1 - cosAngle;
    double r00 = x * x * diffCosAngle + cosAngle;
    double r10 = x * y * diffCosAngle + z * sinAngle;
    double r20 = x * z * diffCosAngle - y * sinAngle;

    double r01 = x * y * diffCosAngle - z * sinAngle;
    double r11 = y * y * diffCosAngle + cosAngle;
    double r21 = y * z * diffCosAngle + x * sinAngle;

    double r02 = x * z * diffCosAngle + y * sinAngle;
    double r12 = y * z * diffCosAngle - x * sinAngle;
    double r22 = z * z * diffCosAngle + cosAngle;

    _googSetFromValues(
        mat,
        m00 * r00 + m01 * r10 + m02 * r20,
        m10 * r00 + m11 * r10 + m12 * r20,
        m20 * r00 + m21 * r10 + m22 * r20,
        m30 * r00 + m31 * r10 + m32 * r20,

        m00 * r01 + m01 * r11 + m02 * r21,
        m10 * r01 + m11 * r11 + m12 * r21,
        m20 * r01 + m21 * r11 + m22 * r21,
        m30 * r01 + m31 * r11 + m32 * r21,

        m00 * r02 + m01 * r12 + m02 * r22,
        m10 * r02 + m11 * r12 + m12 * r22,
        m20 * r02 + m21 * r12 + m22 * r22,
        m30 * r02 + m31 * r12 + m32 * r22,

        m03, m13, m23, m33);

//    return /** @type {!goog.vec.Mat4.Mat4Like} */ (mat);
  }

  static void _googSetFromValues(
      List<double> mat, double v00, double v10, double v20, double v30, 
      double v01, double v11, double v21, double v31, 
      double v02, double v12, double v22, double v32,
      double v03, double v13, double v23, double v33) {
    mat[0] = v00;
    mat[1] = v10;
    mat[2] = v20;
    mat[3] = v30;
    mat[4] = v01;
    mat[5] = v11;
    mat[6] = v21;
    mat[7] = v31;
    mat[8] = v02;
    mat[9] = v12;
    mat[10] = v22;
    mat[11] = v32;
    mat[12] = v03;
    mat[13] = v13;
    mat[14] = v23;
    mat[15] = v33;
  }
  /**
   * Sets the matrix from the array of values stored in column major order.
   *
   * @param {goog.vec.Mat4.Mat4Like} mat The matrix to receive the values.
   * @param {goog.vec.Mat4.Mat4Like} values The column major ordered
   *     array of values to store in the matrix.
   */
   static void _googSetFromArray(List<double> mat, List<double> values) {
    mat[0] = values[0];
    mat[1] = values[1];
    mat[2] = values[2];
    mat[3] = values[3];
    mat[4] = values[4];
    mat[5] = values[5];
    mat[6] = values[6];
    mat[7] = values[7];
    mat[8] = values[8];
    mat[9] = values[9];
    mat[10] = values[10];
    mat[11] = values[11];
    mat[12] = values[12];
    mat[13] = values[13];
    mat[14] = values[14];
    mat[15] = values[15];
  }

  /**
   * Translates the given matrix by x,y,z.  Equvialent to:
   * goog.vec.Mat4.multMat(
   *     mat,
   *     goog.vec.Mat4.makeTranslate(goog.vec.Mat4.create(), x, y, z),
   *     mat);
   *
   * @param {goog.vec.Mat4.Mat4Like} mat The matrix.
   * @param {number} x The translation along the x axis.
   * @param {number} y The translation along the y axis.
   * @param {number} z The translation along the z axis.
   * @return {!goog.vec.Mat4.Mat4Like} return mat so that operations can be
   *     chained.
   */
   static void _googTranslate(List<double> mat, double x, double y, double z) {
    _googSetColumnValues(
        mat, 3,
        mat[0] * x + mat[4] * y + mat[8] * z + mat[12],
        mat[1] * x + mat[5] * y + mat[9] * z + mat[13],
        mat[2] * x + mat[6] * y + mat[10] * z + mat[14],
        mat[3] * x + mat[7] * y + mat[11] * z + mat[15]);
//    return /** @type {!goog.vec.Mat4.Mat4Like} */ (mat);
  }

  /**
   * Sets the specified column with the supplied values.
   *
   * @param {goog.vec.Mat4.Mat4Like} mat The matrix to recieve the values.
   * @param {number} column The column index to set the values on.
   * @param {number} v0 The value for row 0.
   * @param {number} v1 The value for row 1.
   * @param {number} v2 The value for row 2.
   * @param {number} v3 The value for row 3.
   */
   static void _googSetColumnValues(List<double> mat, int column, double v0, double v1, double v2, double v3) {
    int i = column * 4;
    mat[i] = v0;
    mat[i + 1] = v1;
    mat[i + 2] = v2;
    mat[i + 3] = v3;
  }
  
  static List<double> _googScale(List<double> mat, double x, double y, double z) {
    _googSetFromValues(
        mat,
        mat[0] * x, mat[1] * x, mat[2] * x, mat[3] * x,
        mat[4] * y, mat[5] * y, mat[6] * y, mat[7] * y,
        mat[8] * z, mat[9] * z, mat[10] * z, mat[11] * z,
        mat[12], mat[13], mat[14], mat[15]);
    return /** @type {!goog.vec.Mat4.Mat4Like} */ (mat);
  }

}



