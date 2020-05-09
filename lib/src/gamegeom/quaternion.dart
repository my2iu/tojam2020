
/*******************************************************************************
 * Copyright 2011 See AUTHORS file.
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *   http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 ******************************************************************************/

//package com.badlogic.gdx.math;

import 'dart:math' as Math;
import 'Mat4.dart';

//import com.badlogic.gdx.utils.NumberUtils;

/** A simple quaternion class.
 * @see <a href="http://en.wikipedia.org/wiki/Quaternion">http://en.wikipedia.org/wiki/Quaternion</a>
 * @author badlogicgames@gmail.com
 * @author vesuvio
 * @author xoppa */
class Quaternion  {
    //private static final long serialVersionUID = -7661875440774897168L;
     static Quaternion _tmp1 = new Quaternion(0, 0, 0, 0);
     static Quaternion _tmp2 = new Quaternion(0, 0, 0, 0);

     double x;
     double y;
     double z;
     double w;

    Quaternion.I() {
        idt();
    }

    /** Constructor, sets the four components of the quaternion.
     * @param x The x-component
     * @param y The y-component
     * @param z The z-component
     * @param w The w-component */
     Quaternion(double x, double y, double z, double w) {
        this.set(x, y, z, w);
    }


    /** Constructor, sets the quaternion components from the given quaternion.
     * 
     * @param quaternion The quaternion to copy. */
     Quaternion.from(Quaternion quaternion) {
        this.setFrom(quaternion);
    }

    /** Constructor, sets the quaternion from the given axis vector and the angle around that axis in degrees.
     * 
     * @param axis The axis
     * @param angle The angle in degrees. */
//    public Quaternion (Vector3 axis, double angle) {
//        this.set(axis, angle);
//    }

    /** Sets the components of the quaternion
     * @param x The x-component
     * @param y The y-component
     * @param z The z-component
     * @param w The w-component
     * @return This quaternion for chaining */
     Quaternion set (double x, double y, double z, double w) {
        this.x = x;
        this.y = y;
        this.z = z;
        this.w = w;
        return this;
    }

    /** Sets the quaternion components from the given quaternion.
     * @param quaternion The quaternion.
     * @return This quaternion for chaining. */
     Quaternion setFrom (Quaternion quaternion) {
        return this.set(quaternion.x, quaternion.y, quaternion.z, quaternion.w);
    }

    /** Sets the quaternion components from the given axis and angle around that axis.
     * 
     * @param axis The axis
     * @param angle The angle in degrees
     * @return This quaternion for chaining. */
//    public Quaternion set (Vector3 axis, double angle) {
//        return setFromAxis(axis.x, axis.y, axis.z, angle);
//    }

    /** @return a copy of this quaternion */
     Quaternion cpy () {
        return Quaternion.from(this);
    }

    /** @return the euclidean length of the specified quaternion */
    /* final*/ static double lenOf (final double x, final double y, final double z, final double w) {
        return Math.sqrt(x * x + y * y + z * z + w * w);
    }

    /** @return the euclidean length of this quaternion */
    double len () {
        return Math.sqrt(x * x + y * y + z * z + w * w);
    }

     String toString () {
        return "[" + x.toString() + "|" + y.toString() + "|" + z.toString() + "|" + w.toString() + "]";
    }

    /** Sets the quaternion to the given euler angles in degrees.
     * @param yaw the rotation around the y axis in degrees
     * @param pitch the rotation around the x axis in degrees
     * @param roll the rotation around the z axis degrees
     * @return this quaternion */
     Quaternion setEulerAngles (double yaw, double pitch, double roll) {
        return setEulerAnglesRad(yaw * MathUtils.degreesToRadians, pitch * MathUtils.degreesToRadians, roll
            * MathUtils.degreesToRadians);
    }

    /** Sets the quaternion to the given euler angles in radians.
     * @param yaw the rotation around the y axis in radians
     * @param pitch the rotation around the x axis in radians
     * @param roll the rotation around the z axis in radians
     * @return this quaternion */
     Quaternion setEulerAnglesRad (double yaw, double pitch, double roll) {
        final double hr = roll * 0.5;
        final double shr = Math.sin(hr);
        final double chr = Math.cos(hr);
        final double hp = pitch * 0.5;
        final double shp = Math.sin(hp);
        final double chp = Math.cos(hp);
        final double hy = yaw * 0.5;
        final double shy = Math.sin(hy);
        final double chy = Math.cos(hy);
        final double chy_shp = chy * shp;
        final double shy_chp = shy * chp;
        final double chy_chp = chy * chp;
        final double shy_shp = shy * shp;

        x = (chy_shp * chr) + (shy_chp * shr); // cos(yaw/2) * sin(pitch/2) * cos(roll/2) + sin(yaw/2) * cos(pitch/2) * sin(roll/2)
        y = (shy_chp * chr) - (chy_shp * shr); // sin(yaw/2) * cos(pitch/2) * cos(roll/2) - cos(yaw/2) * sin(pitch/2) * sin(roll/2)
        z = (chy_chp * shr) - (shy_shp * chr); // cos(yaw/2) * cos(pitch/2) * sin(roll/2) - sin(yaw/2) * sin(pitch/2) * cos(roll/2)
        w = (chy_chp * chr) + (shy_shp * shr); // cos(yaw/2) * cos(pitch/2) * cos(roll/2) + sin(yaw/2) * sin(pitch/2) * sin(roll/2)
        return this;
    }

    /** Get the pole of the gimbal lock, if any. 
     * @return positive (+1) for north pole, negative (-1) for south pole, zero (0) when no gimbal lock */ 
     int getGimbalPole() {
        final double t = y*x+z*w;
        return t > 0.499 ? 1 : (t < -0.499 ? -1 : 0);
    }
    
    /** Get the roll euler angle in radians, which is the rotation around the z axis. Requires that this quaternion is normalized. 
     * @return the rotation around the z axis in radians (between -PI and +PI) */
     double getRollRad() {
        final int pole = getGimbalPole();
        return pole == 0 ? MathUtils.atan2(2*(w*z + y*x), 1 - 2 * (x*x + z*z)) : pole * 2 * MathUtils.atan2(y, w);
    }
    
    /** Get the roll euler angle in degrees, which is the rotation around the z axis. Requires that this quaternion is normalized. 
     * @return the rotation around the z axis in degrees (between -180 and +180) */
     double getRoll() {
        return getRollRad() * MathUtils.radiansToDegrees;
    }
    
    /** Get the pitch euler angle in radians, which is the rotation around the x axis. Requires that this quaternion is normalized. 
     * @return the rotation around the x axis in radians (between -(PI/2) and +(PI/2)) */
     double getPitchRad() {
        final int pole = getGimbalPole();
        return pole == 0 ? Math.asin(MathUtils.clamp(2*(w*x-z*y), -1, 1)) : pole * MathUtils.PI * 0.5;
    }

    /** Get the pitch euler angle in degrees, which is the rotation around the x axis. Requires that this quaternion is normalized. 
     * @return the rotation around the x axis in degrees (between -90 and +90) */
     double getPitch() {
        return getPitchRad() * MathUtils.radiansToDegrees;
    }
    
    /** Get the yaw euler angle in radians, which is the rotation around the y axis. Requires that this quaternion is normalized. 
     * @return the rotation around the y axis in radians (between -PI and +PI) */
     double getYawRad() {
        return getGimbalPole() == 0 ? MathUtils.atan2(2*(y*w + x*z), 1 - 2*(y*y+x*x)) : 0;
    }
    
    /** Get the yaw euler angle in degrees, which is the rotation around the y axis. Requires that this quaternion is normalized. 
     * @return the rotation around the y axis in degrees (between -180 and +180) */
     double getYaw() {
        return getYawRad() * MathUtils.radiansToDegrees;
    }

    /* final */static double len2Of (final double x, final double y, final double z, final double w) {
        return x * x + y * y + z * z + w * w;
    }

    /** @return the length of this quaternion without square root */
     double len2 () {
        return x * x + y * y + z * z + w * w;
    }

    /** Normalizes this quaternion to unit length
     * @return the quaternion for chaining */
     Quaternion nor () {
        double len = len2();
        if (len != 0 && !MathUtils.isEqual(len, 1)) {
            len = Math.sqrt(len);
            w /= len;
            x /= len;
            y /= len;
            z /= len;
        }
        return this;
    }

    /** Conjugate the quaternion.
     * 
     * @return This quaternion for chaining */
     Quaternion conjugate () {
        x = -x;
        y = -y;
        z = -z;
        return this;
    }

    // TODO : this would better fit into the vector3 class
    /** Transforms the given vector using this quaternion
     * 
     * @param v Vector to transform */
     List<double> transform (List<double> v) {
        _tmp2.setFrom(this);
        _tmp2.conjugate();
        _tmp2.mulLeft(_tmp1.set(v[0], v[1], v[2], 0)).mulLeft(this);

        v[0] = _tmp2.x;
        v[1] = _tmp2.y;
        v[2] = _tmp2.z;
        return v;
    }

  //   List<double> transform (List<double> v) {
  //     _tmp2.setFrom(this);
  //     _tmp2.conjugate();
  //     _tmp2.mulLeft(_tmp1.set(v[0], v[1], v[2], 0)).mulLeft(this);

  //     v[0] = _tmp2.x;
  //     v[1] = _tmp2.y;
  //     v[2] = _tmp2.z;
  //     return v;
  // }

    /** Multiplies this quaternion with another one in the form of this = this * other
     * 
     * @param other Quaternion to multiply with
     * @return This quaternion for chaining */
     Quaternion mul (final Quaternion other) {
        final double newX = this.w * other.x + this.x * other.w + this.y * other.z - this.z * other.y;
        final double newY = this.w * other.y + this.y * other.w + this.z * other.x - this.x * other.z;
        final double newZ = this.w * other.z + this.z * other.w + this.x * other.y - this.y * other.x;
        final double newW = this.w * other.w - this.x * other.x - this.y * other.y - this.z * other.z;
        this.x = newX;
        this.y = newY;
        this.z = newZ;
        this.w = newW;
        return this;
    }

    /** Multiplies this quaternion with another one in the form of this = this * other
     * 
     * @param x the x component of the other quaternion to multiply with
     * @param y the y component of the other quaternion to multiply with
     * @param z the z component of the other quaternion to multiply with
     * @param w the w component of the other quaternion to multiply with
     * @return This quaternion for chaining */
     Quaternion mulFrom (final double x, final double y, final double z, final double w) {
        final double newX = this.w * x + this.x * w + this.y * z - this.z * y;
        final double newY = this.w * y + this.y * w + this.z * x - this.x * z;
        final double newZ = this.w * z + this.z * w + this.x * y - this.y * x;
        final double newW = this.w * w - this.x * x - this.y * y - this.z * z;
        this.x = newX;
        this.y = newY;
        this.z = newZ;
        this.w = newW;
        return this;
    }

    /** Multiplies this quaternion with another one in the form of this = other * this
     * 
     * @param other Quaternion to multiply with
     * @return This quaternion for chaining */
     Quaternion mulLeft (Quaternion other) {
        final double newX = other.w * this.x + other.x * this.w + other.y * this.z - other.z * y;
        final double newY = other.w * this.y + other.y * this.w + other.z * this.x - other.x * z;
        final double newZ = other.w * this.z + other.z * this.w + other.x * this.y - other.y * x;
        final double newW = other.w * this.w - other.x * this.x - other.y * this.y - other.z * z;
        this.x = newX;
        this.y = newY;
        this.z = newZ;
        this.w = newW;
        return this;
    }

    /** Multiplies this quaternion with another one in the form of this = other * this
     * 
     * @param x the x component of the other quaternion to multiply with
     * @param y the y component of the other quaternion to multiply with
     * @param z the z component of the other quaternion to multiply with
     * @param w the w component of the other quaternion to multiply with
     * @return This quaternion for chaining */
     Quaternion mulLeftFrom (final double x, final double y, final double z, final double w) {
        final double newX = w * this.x + x * this.w + y * this.z - z * y;
        final double newY = w * this.y + y * this.w + z * this.x - x * z;
        final double newZ = w * this.z + z * this.w + x * this.y - y * x;
        final double newW = w * this.w - x * this.x - y * this.y - z * z;
        this.x = newX;
        this.y = newY;
        this.z = newZ;
        this.w = newW;
        return this;
    }
    
    /** Add the x,y,z,w components of the passed in quaternion to the ones of this quaternion */
     Quaternion add(Quaternion quaternion){
        this.x += quaternion.x;
        this.y += quaternion.y;
        this.z += quaternion.z;
        this.w += quaternion.w;
        return this;
    }
    
    /** Add the x,y,z,w components of the passed in quaternion to the ones of this quaternion */
     Quaternion addFrom(double qx, double qy, double qz, double qw){
        this.x += qx;
        this.y += qy;
        this.z += qz;
        this.w += qw;
        return this;
    }
    
    // TODO : the matrix4 set(quaternion) doesnt set the last row+col of the matrix to 0,0,0,1 so... that's why there is this
// method
    /** Fills a 4x4 matrix with the rotation matrix represented by this quaternion.
     * 
     * @param matrix Matrix to fill */
     void toMatrix (final List<double> matrix) {
        final double xx = x * x;
        final double xy = x * y;
        final double xz = x * z;
        final double xw = x * w;
        final double yy = y * y;
        final double yz = y * z;
        final double yw = y * w;
        final double zz = z * z;
        final double zw = z * w;
        // Set matrix from quaternion
        matrix[Matrix4.M00] = 1 - 2 * (yy + zz);
        matrix[Matrix4.M01] = 2 * (xy - zw);
        matrix[Matrix4.M02] = 2 * (xz + yw);
        matrix[Matrix4.M03] = 0;
        matrix[Matrix4.M10] = 2 * (xy + zw);
        matrix[Matrix4.M11] = 1 - 2 * (xx + zz);
        matrix[Matrix4.M12] = 2 * (yz - xw);
        matrix[Matrix4.M13] = 0;
        matrix[Matrix4.M20] = 2 * (xz - yw);
        matrix[Matrix4.M21] = 2 * (yz + xw);
        matrix[Matrix4.M22] = 1 - 2 * (xx + yy);
        matrix[Matrix4.M23] = 0;
        matrix[Matrix4.M30] = 0;
        matrix[Matrix4.M31] = 0;
        matrix[Matrix4.M32] = 0;
        matrix[Matrix4.M33] = 1;
    }

  //    void toMatrix (final List<double> matrix) {
  //     final double xx = x * x;
  //     final double xy = x * y;
  //     final double xz = x * z;
  //     final double xw = x * w;
  //     final double yy = y * y;
  //     final double yz = y * z;
  //     final double yw = y * w;
  //     final double zz = z * z;
  //     final double zw = z * w;
  //     // Set matrix from quaternion
  //     matrix[Matrix4.M00] = 1 - 2 * (yy + zz);
  //     matrix[Matrix4.M01] = 2 * (xy - zw);
  //     matrix[Matrix4.M02] = 2 * (xz + yw);
  //     matrix[Matrix4.M03] = 0;
  //     matrix[Matrix4.M10] = 2 * (xy + zw);
  //     matrix[Matrix4.M11] = 1 - 2 * (xx + zz);
  //     matrix[Matrix4.M12] = 2 * (yz - xw);
  //     matrix[Matrix4.M13] = 0;
  //     matrix[Matrix4.M20] = 2 * (xz - yw);
  //     matrix[Matrix4.M21] = 2 * (yz + xw);
  //     matrix[Matrix4.M22] = 1 - 2 * (xx + yy);
  //     matrix[Matrix4.M23] = 0;
  //     matrix[Matrix4.M30] = 0;
  //     matrix[Matrix4.M31] = 0;
  //     matrix[Matrix4.M32] = 0;
  //     matrix[Matrix4.M33] = 1;
  // }

    /** Sets the quaternion to an identity Quaternion
     * @return this quaternion for chaining */
     Quaternion idt () {
        return this.set(0, 0, 0, 1);
    }

    /** @return If this quaternion is an identity Quaternion */
     bool isIdentity () {
        return MathUtils.isZero(x) && MathUtils.isZero(y) && MathUtils.isZero(z) && MathUtils.isEqual(w, 1);
    }

    /** @return If this quaternion is an identity Quaternion */
     bool isNearIdentity (final double tolerance) {
        return MathUtils.isNearZero(x, tolerance) && MathUtils.isNearZero(y, tolerance) && MathUtils.isNearZero(z, tolerance)
            && MathUtils.isNearEqual(w, 1, tolerance);
    }

    // todo : the setFromAxis(v3,double) method should replace the set(v3,double) method
    /** Sets the quaternion components from the given axis and angle around that axis.
     * 
     * @param axis The axis
     * @param degrees The angle in degrees
     * @return This quaternion for chaining. */
//    public Quaternion setFromAxis (final Vector3 axis, final double degrees) {
//        return setFromAxis(axis.x, axis.y, axis.z, degrees);
//    }

    /** Sets the quaternion components from the given axis and angle around that axis.
     * 
     * @param axis The axis
     * @param radians The angle in radians
     * @return This quaternion for chaining. */
//    public Quaternion setFromAxisRad (final Vector3 axis, final double radians) {
//        return setFromAxisRad(axis.x, axis.y, axis.z, radians);
//    }

    /** Sets the quaternion components from the given axis and angle around that axis.
     * @param x X direction of the axis
     * @param y Y direction of the axis
     * @param z Z direction of the axis
     * @param degrees The angle in degrees
     * @return This quaternion for chaining. */
     Quaternion setFromAxis (final double x, final double y, final double z, final double degrees) {
        return setFromAxisRad(x, y, z, degrees * MathUtils.degreesToRadians);
    }

    /** Sets the quaternion components from the given axis and angle around that axis.
     * @param x X direction of the axis
     * @param y Y direction of the axis
     * @param z Z direction of the axis
     * @param radians The angle in radians
     * @return This quaternion for chaining. */
     Quaternion setFromAxisRad (final double x, final double y, final double z, final double radians) {
        double d = Vector3.len(x, y, z);
        if (d == 0) return idt();
        d = 1 / d;
        double l_ang = radians < 0 ? MathUtils.PI2 - (-radians % MathUtils.PI2) : radians % MathUtils.PI2;
        double l_sin = Math.sin(l_ang / 2);
        double l_cos = Math.cos(l_ang / 2);
        return this.set(d * x * l_sin, d * y * l_sin, d * z * l_sin, l_cos).nor();
    }

    /** Sets the Quaternion from the given matrix, optionally removing any scaling. */
     Quaternion setFromMat4Normalize (bool normalizeAxes, Mat4 matrix) {
        return setFromAxesNormalize(normalizeAxes, matrix.data[Matrix4.M00], matrix.data[Matrix4.M01], matrix.data[Matrix4.M02],
            matrix.data[Matrix4.M10], matrix.data[Matrix4.M11], matrix.data[Matrix4.M12], matrix.data[Matrix4.M20],
            matrix.data[Matrix4.M21], matrix.data[Matrix4.M22]);
    }

    /** Sets the Quaternion from the given rotation matrix, which must not contain scaling. */
     Quaternion setFromMat4 (Mat4 matrix) {
        return setFromMat4Normalize(false, matrix);
    }

    Mat4 toMat4() {
      List<double> rotateMatrixArray = new List<double>(16);
      toMatrix(rotateMatrixArray);
      Mat4 rotateMatrix = new Mat4(rotateMatrixArray);
      rotateMatrix = rotateMatrix.transpose();
      return rotateMatrix;
    }
    // TODO: Seems broken
     Quaternion setFromMatrixNormalize (bool normalizeAxes, List<double>matrix) {
      return setFromAxesNormalize(normalizeAxes, matrix[Matrix4.M00], matrix[Matrix4.M01], matrix[Matrix4.M02],
          matrix[Matrix4.M10], matrix[Matrix4.M11], matrix[Matrix4.M12], matrix[Matrix4.M20],
          matrix[Matrix4.M21], matrix[Matrix4.M22]);
    }
    
    // from: http://www.euclideanspace.com/maths/geometry/rotations/conversions/matrixToQuaternion/
     Quaternion setFromMatrix(double m00, double m01, double m02, 
        double m10, double m11, double m12, 
        double m20, double m21, double m22)
    {
      double tr = m00 + m11 + m22;

          if (tr > 0) { 
            double S = Math.sqrt(tr+1.0) * 2; // S=4*qw 
            w = (0.25 * S);
            x = ((m21 - m12) / S);
            y = ((m02 - m20) / S); 
            z = ((m10 - m01) / S); 
          } else if ((m00 > m11)&(m00 > m22)) { 
            double S = Math.sqrt(1.0 + m00 - m11 - m22) * 2; // S=4*qx 
            w = ((m21 - m12) / S);
            x = (0.25 * S);
            y = ((m01 + m10) / S); 
            z = ((m02 + m20) / S); 
          } else if (m11 > m22) { 
            double S = Math.sqrt(1.0 + m11 - m00 - m22) * 2; // S=4*qy
            w = ((m02 - m20) / S);
            x = ((m01 + m10) / S); 
            y = (0.25 * S);
            z = ((m12 + m21) / S); 
          } else { 
            double S = Math.sqrt(1.0 + m22 - m00 - m11) * 2; // S=4*qz
            w = ((m10 - m01) / S);
            x = ((m02 + m20) / S);
            y = ((m12 + m21) / S);
            z = (0.25 * S);
          }
          return this;
    }
    
     Quaternion setLookAt(List<double> direction, List<double>up)
    {
      List<double>matrix = Matrix4.setToLookAt(direction, up);
      return setFromMatrix(matrix[0], matrix[1], matrix[2],
          matrix[4], matrix[5], matrix[6],
          matrix[8], matrix[9], matrix[10]
              );
    }

    /** Sets the Quaternion from the given matrix, optionally removing any scaling. */
//    public Quaternion setFromMatrix (boolean normalizeAxes, Matrix3 matrix) {
//        return setFromAxes(normalizeAxes, matrix.val[Matrix3.M00], matrix.val[Matrix3.M01], matrix.val[Matrix3.M02],
//            matrix.val[Matrix3.M10], matrix.val[Matrix3.M11], matrix.val[Matrix3.M12], matrix.val[Matrix3.M20],
//            matrix.val[Matrix3.M21], matrix.val[Matrix3.M22]);
//    }

    /** Sets the Quaternion from the given rotation matrix, which must not contain scaling. */
//    public Quaternion setFromMatrix (Matrix3 matrix) {
//        return setFromMatrix(false, matrix);
//    }

    /** <p>
     * Sets the Quaternion from the given x-, y- and z-axis which have to be orthonormal.
     * </p>
     * 
     * <p>
     * Taken from Bones framework for JPCT, see http://www.aptalkarga.com/bones/ which in turn took it from Graphics Gem code at
     * ftp://ftp.cis.upenn.edu/pub/graphics/shoemake/quatut.ps.Z.
     * </p>
     * 
     * @param xx x-axis x-coordinate
     * @param xy x-axis y-coordinate
     * @param xz x-axis z-coordinate
     * @param yx y-axis x-coordinate
     * @param yy y-axis y-coordinate
     * @param yz y-axis z-coordinate
     * @param zx z-axis x-coordinate
     * @param zy z-axis y-coordinate
     * @param zz z-axis z-coordinate */
     Quaternion setFromAxes (double xx, double xy, double xz, double yx, double yy, double yz, double zx, double zy, double zz) {
        return setFromAxesNormalize(false, xx, xy, xz, yx, yy, yz, zx, zy, zz);
    }

    /** <p>
     * Sets the Quaternion from the given x-, y- and z-axis.
     * </p>
     * 
     * <p>
     * Taken from Bones framework for JPCT, see http://www.aptalkarga.com/bones/ which in turn took it from Graphics Gem code at
     * ftp://ftp.cis.upenn.edu/pub/graphics/shoemake/quatut.ps.Z.
     * </p>
     * 
     * @param normalizeAxes whether to normalize the axes (necessary when they contain scaling)
     * @param xx x-axis x-coordinate
     * @param xy x-axis y-coordinate
     * @param xz x-axis z-coordinate
     * @param yx y-axis x-coordinate
     * @param yy y-axis y-coordinate
     * @param yz y-axis z-coordinate
     * @param zx z-axis x-coordinate
     * @param zy z-axis y-coordinate
     * @param zz z-axis z-coordinate */
     Quaternion setFromAxesNormalize (bool normalizeAxes, double xx, double xy, double xz, double yx, double yy, double yz, double zx,
        double zy, double zz) {
        if (normalizeAxes) {
            final double lx = 1 / Vector3.len(xx, xy, xz);
            final double ly = 1 / Vector3.len(yx, yy, yz);
            final double lz = 1 / Vector3.len(zx, zy, zz);
            xx *= lx;
            xy *= lx;
            xz *= lx;
            yx *= ly;
            yy *= ly;
            yz *= ly;
            zx *= lz;
            zy *= lz;
            zz *= lz;
        }
        // the trace is the sum of the diagonal elements; see
        // http://mathworld.wolfram.com/MatrixTrace.html
        final double t = xx + yy + zz;

        // we protect the division by s by ensuring that s>=1
        if (t >= 0) { // |w| >= .5
            double s = Math.sqrt(t + 1); // |s|>=1 ...
            w = 0.5 * s;
            s = 0.5 / s; // so this division isn't bad
            x = (zy - yz) * s;
            y = (xz - zx) * s;
            z = (yx - xy) * s;
        } else if ((xx > yy) && (xx > zz)) {
            double s = Math.sqrt(1.0 + xx - yy - zz); // |s|>=1
            x = s * 0.5; // |x| >= .5
            s = 0.5 / s;
            y = (yx + xy) * s;
            z = (xz + zx) * s;
            w = (zy - yz) * s;
        } else if (yy > zz) {
            double s = Math.sqrt(1.0 + yy - xx - zz); // |s|>=1
            y = s * 0.5; // |y| >= .5
            s = 0.5 / s;
            x = (yx + xy) * s;
            z = (zy + yz) * s;
            w = (xz - zx) * s;
        } else {
            double s = Math.sqrt(1.0 + zz - xx - yy); // |s|>=1
            z = s * 0.5; // |z| >= .5
            s = 0.5 / s;
            x = (xz + zx) * s;
            y = (zy + yz) * s;
            w = (yx - xy) * s;
        }

        return this;
    }

    /** Set this quaternion to the rotation between two vectors.
     * @param v1 The base vector, which should be normalized.
     * @param v2 The target vector, which should be normalized.
     * @return This quaternion for chaining */
//    public Quaternion setFromCross (final Vector3 v1, final Vector3 v2) {
//        final double dot = MathUtils.clamp(v1.dot(v2), -1f, 1f);
//        final double angle = Math.acos(dot);
//        return setFromAxisRad(v1.y * v2.z - v1.z * v2.y, v1.z * v2.x - v1.x * v2.z, v1.x * v2.y - v1.y * v2.x, angle);
//    }

    /** Set this quaternion to the rotation between two vectors.
     * @param x1 The base vectors x value, which should be normalized.
     * @param y1 The base vectors y value, which should be normalized.
     * @param z1 The base vectors z value, which should be normalized.
     * @param x2 The target vector x value, which should be normalized.
     * @param y2 The target vector y value, which should be normalized.
     * @param z2 The target vector z value, which should be normalized.
     * @return This quaternion for chaining */
     Quaternion setFromCross (final double x1, final double y1, final double z1, final double x2, final double y2, final double z2) {
        final double dot = MathUtils.clamp(Vector3.dot(x1, y1, z1, x2, y2, z2), -1, 1);
        final double angle = Math.acos(dot);
        return setFromAxisRad(y1 * z2 - z1 * y2, z1 * x2 - x1 * z2, x1 * y2 - y1 * x2, angle);
    }

    /** Spherical linear interpolation between this quaternion and the other quaternion, based on the alpha value in the range
     * [0,1]. Taken from. Taken from Bones framework for JPCT, see http://www.aptalkarga.com/bones/
     * @param end the end quaternion
     * @param alpha alpha in the range [0,1]
     * @return this quaternion for chaining */
     Quaternion slerp (Quaternion end, double alpha) {
        final double d = this.x * end.x + this.y * end.y + this.z * end.z + this.w * end.w;
        double absDot = d < 0 ? -d : d;

        // Set the first and second scale for the interpolation
        double scale0 = 1 - alpha;
        double scale1 = alpha;

        // Check if the angle between the 2 quaternions was big enough to
        // warrant such calculations
        if ((1 - absDot) > 0.1) {// Get the angle between the 2 quaternions,
            // and then store the sin() of that angle
            final double angle = Math.acos(absDot);
            final double invSinTheta = 1 / Math.sin(angle);

            // Calculate the scale for q1 and q2, according to the angle and
            // it's sine value
            scale0 = (Math.sin((1 - alpha) * angle) * invSinTheta);
            scale1 = (Math.sin((alpha * angle)) * invSinTheta);
        }

        if (d < 0) scale1 = -scale1;

        // Calculate the x, y, z and w values for the quaternion by using a
        // special form of linear interpolation for quaternions.
        x = (scale0 * x) + (scale1 * end.x);
        y = (scale0 * y) + (scale1 * end.y);
        z = (scale0 * z) + (scale1 * end.z);
        w = (scale0 * w) + (scale1 * end.w);

        // Return the interpolated quaternion
        return this;
    }

    /**
     * Spherical linearly interpolates multiple quaternions and stores the result in this Quaternion.
     * Will not destroy the data previously inside the elements of q.
     * result = (q_1^w_1)*(q_2^w_2)* ... *(q_n^w_n) where w_i=1/n.
     * @param q List of quaternions
     * @return This quaternion for chaining */
     Quaternion slerpList (List<Quaternion> q) {
        
        //Calculate exponents and multiply everything from left to right
        final double w = 1.0/q.length;
        setFrom(q[0]).exp(w);
        for(int i=1;i<q.length;i++)
            mul(_tmp1.setFrom(q[i]).exp(w));
        nor();
        return this;
    }
    
    /**
     * Spherical linearly interpolates multiple quaternions by the given weights and stores the result in this Quaternion.
     * Will not destroy the data previously inside the elements of q or w.
     * result = (q_1^w_1)*(q_2^w_2)* ... *(q_n^w_n) where the sum of w_i is 1.
     * Lists must be equal in length.
     * @param q List of quaternions
     * @param w List of weights
     * @return This quaternion for chaining */
     Quaternion slerpListW (List<Quaternion> q, List<double> w) {
        
        //Calculate exponents and multiply everything from left to right
        setFrom(q[0]).exp(w[0]);
        for(int i=1;i<q.length;i++)
            mul(_tmp1.setFrom(q[i]).exp(w[i]));
        nor();
        return this;
    }
    
    /**
     * Calculates (this quaternion)^alpha where alpha is a real number and stores the result in this quaternion.
     * See http://en.wikipedia.org/wiki/Quaternion#Exponential.2C_logarithm.2C_and_power
     * @param alpha Exponent
     * @return This quaternion for chaining */
     Quaternion exp (double alpha) {

        //Calculate |q|^alpha
        double norm = len();
        double normExp = Math.pow(norm, alpha);

        //Calculate theta
        double theta = Math.acos(w / norm);

        //Calculate coefficient of basis elements
        double coeff = 0;
        if(theta.abs() < 0.001) //If theta is small enough, use the limit of sin(alpha*theta) / sin(theta) instead of actual value
            coeff = normExp*alpha / norm;
        else
            coeff = (normExp*Math.sin(alpha*theta) / (norm*Math.sin(theta)));

        //Write results
        w = (normExp*Math.cos(alpha*theta));
        x *= coeff;
        y *= coeff;
        z *= coeff;

        //Fix any possible discrepancies
        nor();

        return this;
    }
    
//    @Override
//    public int hashCode () {
//        final int prime = 31;
//        int result = 1;
//        result = prime * result + NumberUtils.doubleToRawIntBits(w);
//        result = prime * result + NumberUtils.doubleToRawIntBits(x);
//        result = prime * result + NumberUtils.doubleToRawIntBits(y);
//        result = prime * result + NumberUtils.doubleToRawIntBits(z);
//        return result;
//    }
//
//    @Override
//    public boolean equals (Object obj) {
//        if (this == obj) {
//            return true;
//        }
//        if (obj == null) {
//            return false;
//        }
//        if (!(obj instanceof Quaternion)) {
//            return false;
//        }
//        Quaternion other = (Quaternion)obj;
//        return (NumberUtils.doubleToRawIntBits(w) == NumberUtils.doubleToRawIntBits(other.w))
//            && (NumberUtils.doubleToRawIntBits(x) == NumberUtils.doubleToRawIntBits(other.x))
//            && (NumberUtils.doubleToRawIntBits(y) == NumberUtils.doubleToRawIntBits(other.y))
//            && (NumberUtils.doubleToRawIntBits(z) == NumberUtils.doubleToRawIntBits(other.z));
//    }

    /** Get the dot product between the two quaternions (commutative).
     * @param x1 the x component of the first quaternion
     * @param y1 the y component of the first quaternion
     * @param z1 the z component of the first quaternion
     * @param w1 the w component of the first quaternion
     * @param x2 the x component of the second quaternion
     * @param y2 the y component of the second quaternion
     * @param z2 the z component of the second quaternion
     * @param w2 the w component of the second quaternion
     * @return the dot product between the first and second quaternion. */
     /*final*/ static double dotOf (final double x1, final double y1, final double z1, final double w1, final double x2, final double y2,
        final double z2, final double w2) {
        return x1 * x2 + y1 * y2 + z1 * z2 + w1 * w2;
    }

    /** Get the dot product between this and the other quaternion (commutative).
     * @param other the other quaternion.
     * @return the dot product of this and the other quaternion. */
     double dot (final Quaternion other) {
        return this.x * other.x + this.y * other.y + this.z * other.z + this.w * other.w;
    }

    /** Get the dot product between this and the other quaternion (commutative).
     * @param x the x component of the other quaternion
     * @param y the y component of the other quaternion
     * @param z the z component of the other quaternion
     * @param w the w component of the other quaternion
     * @return the dot product of this and the other quaternion. */
     double dotFrom (final double x, final double y, final double z, final double w) {
        return this.x * x + this.y * y + this.z * z + this.w * w;
    }

    /** Multiplies the components of this quaternion with the given scalar.
     * @param scalar the scalar.
     * @return this quaternion for chaining. */
     Quaternion mulScalar (double scalar) {
        this.x *= scalar;
        this.y *= scalar;
        this.z *= scalar;
        this.w *= scalar;
        return this;
    }

    /** Get the axis angle representation of the rotation in degrees. The supplied vector will receive the axis (x, y and z values)
     * of the rotation and the value returned is the angle in degrees around that axis. Note that this method will alter the
     * supplied vector, the existing value of the vector is ignored. </p> This will normalize this quaternion if needed. The
     * received axis is a unit vector. However, if this is an identity quaternion (no rotation), then the length of the axis may be
     * zero.
     * 
     * @param axis vector which will receive the axis
     * @return the angle in degrees
     * @see <a href="http://en.wikipedia.org/wiki/Axis%E2%80%93angle_representation">wikipedia</a>
     * @see <a href="http://www.euclideanspace.com/maths/geometry/rotations/conversions/quaternionToAngle">calculation</a> */
//    public double getAxisAngle (Vector3 axis) {
//        return getAxisAngleRad(axis) * MathUtils.radiansToDegrees;
//    }

    /** Get the axis-angle representation of the rotation in radians. The supplied vector will receive the axis (x, y and z values)
     * of the rotation and the value returned is the angle in radians around that axis. Note that this method will alter the
     * supplied vector, the existing value of the vector is ignored. </p> This will normalize this quaternion if needed. The
     * received axis is a unit vector. However, if this is an identity quaternion (no rotation), then the length of the axis may be
     * zero.
     * 
     * @param axis vector which will receive the axis
     * @return the angle in radians
     * @see <a href="http://en.wikipedia.org/wiki/Axis%E2%80%93angle_representation">wikipedia</a>
     * @see <a href="http://www.euclideanspace.com/maths/geometry/rotations/conversions/quaternionToAngle">calculation</a> */
//    public double getAxisAngleRad (Vector3 axis) {
//        if (this.w > 1) this.nor(); // if w>1 acos and sqrt will produce errors, this cant happen if quaternion is normalised
//        double angle = (2.0 * Math.acos(this.w));
//        double s = Math.sqrt(1 - this.w * this.w); // assuming quaternion normalised then w is less than 1, so term always positive.
//        if (s < MathUtils.double_ROUNDING_ERROR) { // test to avoid divide by zero, s is always positive due to sqrt
//            // if s close to zero then direction of axis not important
//            axis.x = this.x; // if it is important that axis is normalised then replace with x=1; y=z=0;
//            axis.y = this.y;
//            axis.z = this.z;
//        } else {
//            axis.x = (this.x / s); // normalise axis
//            axis.y = (this.y / s);
//            axis.z = (this.z / s);
//        }
//
//        return angle;
//    }

    /** Get the angle in radians of the rotation this quaternion represents. Does not normalize the quaternion. Use
     * {@link #getAxisAngleRad(Vector3)} to get both the axis and the angle of this rotation. Use
     * {@link #getAngleAroundRad(Vector3)} to get the angle around a specific axis.
     * @return the angle in radians of the rotation */
     double getAngleRad () {
        return (2.0 * Math.acos((this.w > 1) ? (this.w / len()) : this.w));
    }

    /** Get the angle in degrees of the rotation this quaternion represents. Use {@link #getAxisAngle(Vector3)} to get both the axis
     * and the angle of this rotation. Use {@link #getAngleAround(Vector3)} to get the angle around a specific axis.
     * @return the angle in degrees of the rotation */
     double getAngle () {
        return getAngleRad() * MathUtils.radiansToDegrees;
    }

    /** Get the swing rotation and twist rotation for the specified axis. The twist rotation represents the rotation around the
     * specified axis. The swing rotation represents the rotation of the specified axis itself, which is the rotation around an
     * axis perpendicular to the specified axis.
     * </p>
     * The swing and twist rotation can be used to reconstruct the original quaternion: this = swing * twist
     * 
     * @param axisX the X component of the normalized axis for which to get the swing and twist rotation
     * @param axisY the Y component of the normalized axis for which to get the swing and twist rotation
     * @param axisZ the Z component of the normalized axis for which to get the swing and twist rotation
     * @param swing will receive the swing rotation: the rotation around an axis perpendicular to the specified axis
     * @param twist will receive the twist rotation: the rotation around the specified axis
     * @see <a href="http://www.euclideanspace.com/maths/geometry/rotations/for/decomposition">calculation</a> */
     void getSwingTwist (final double axisX, final double axisY, final double axisZ, final Quaternion swing,
        final Quaternion twist) {
        final double d = Vector3.dot(this.x, this.y, this.z, axisX, axisY, axisZ);
        twist.set(axisX * d, axisY * d, axisZ * d, this.w).nor();
        swing.setFrom(twist).conjugate().mulLeft(this);
    }

    /** Get the swing rotation and twist rotation for the specified axis. The twist rotation represents the rotation around the
     * specified axis. The swing rotation represents the rotation of the specified axis itself, which is the rotation around an
     * axis perpendicular to the specified axis.
     * </p>
     * The swing and twist rotation can be used to reconstruct the original quaternion: this = swing * twist
     * 
     * @param axis the normalized axis for which to get the swing and twist rotation
     * @param swing will receive the swing rotation: the rotation around an axis perpendicular to the specified axis
     * @param twist will receive the twist rotation: the rotation around the specified axis
     * @see <a href="http://www.euclideanspace.com/maths/geometry/rotations/for/decomposition">calculation</a> */
//    public void getSwingTwist (final Vector3 axis, final Quaternion swing, final Quaternion twist) {
//        getSwingTwist(axis.x, axis.y, axis.z, swing, twist);
//    }

    /** Get the angle in radians of the rotation around the specified axis. The axis must be normalized.
     * @param axisX the x component of the normalized axis for which to get the angle
     * @param axisY the y component of the normalized axis for which to get the angle
     * @param axisZ the z component of the normalized axis for which to get the angle
     * @return the angle in radians of the rotation around the specified axis */
     double getAngleAroundRad (final double axisX, final double axisY, final double axisZ) {
        final double d = Vector3.dot(this.x, this.y, this.z, axisX, axisY, axisZ);
        final double l2 = Quaternion.len2Of(axisX * d, axisY * d, axisZ * d, this.w);
        return MathUtils.isZero(l2) ? 0 : (2.0 * Math.acos(MathUtils.clamp( (this.w / Math.sqrt(l2)), -1, 1)));
    }

    /** Get the angle in radians of the rotation around the specified axis. The axis must be normalized.
     * @param axis the normalized axis for which to get the angle
     * @return the angle in radians of the rotation around the specified axis */
//    public double getAngleAroundRad (final Vector3 axis) {
//        return getAngleAroundRad(axis.x, axis.y, axis.z);
//    }

    /** Get the angle in degrees of the rotation around the specified axis. The axis must be normalized.
     * @param axisX the x component of the normalized axis for which to get the angle
     * @param axisY the y component of the normalized axis for which to get the angle
     * @param axisZ the z component of the normalized axis for which to get the angle
     * @return the angle in degrees of the rotation around the specified axis */
     double getAngleAround (final double axisX, final double axisY, final double axisZ) {
        return getAngleAroundRad(axisX, axisY, axisZ) * MathUtils.radiansToDegrees;
    }

    /** Get the angle in degrees of the rotation around the specified axis. The axis must be normalized.
     * @param axis the normalized axis for which to get the angle
     * @return the angle in degrees of the rotation around the specified axis */
//    public double getAngleAround (final Vector3 axis) {
//        return getAngleAround(axis.x, axis.y, axis.z);
//    }
    
    
}

      class Vector3  {

      /** @return The euclidean length */
       static double len (final double x, final double y, final double z) {
          return Math.sqrt(x * x + y * y + z * z);
      }

    //    static double len (final double x, final double y, final double z) {
    //     return Math.sqrt(x * x + y * y + z * z);
    // }

      /** @return The squared euclidean length */
       static double len2 (final double x, final double y, final double z) {
          return x * x + y * y + z * z;
      }

    //    static double len2 (final double x, final double y, final double z) {
    //     return x * x + y * y + z * z;
    // }

      /** @return The euclidean distance between the two specified vectors */
       static double dst (final double x1, final double y1, final double z1, final double x2, final double y2, final double z2) {
          final double a = x2 - x1;
          final double b = y2 - y1;
          final double c = z2 - z1;
          return Math.sqrt(a * a + b * b + c * c);
      }

      /** @return the squared distance between the given points */
       static double dst2 (final double x1, final double y1, final double z1, final double x2, final double y2, final double z2) {
          final double a = x2 - x1;
          final double b = y2 - y1;
          final double c = z2 - z1;
          return a * a + b * b + c * c;
      }
      
      /** @return The dot product between the two vectors */
       static double dot (double x1, double y1, double z1, double x2, double y2, double z2) {
          return x1 * x2 + y1 * y2 + z1 * z2;
      }
      
       static void set(List<double> result, List<double>value)
      {
        result[0] = value[0];
        result[1] = value[1];
        result[2] = value[2];
      }

       static void setFrom(List<double> result, double x, double y, double z)
      {
        result[0] = x;
        result[1] = y;
        result[2] = z;
      }

       static void crs(List<double> v1, List<double> v2) {
        setFrom(v1, v1[1] * v2[2] - v1[2] * v2[1], v1[2] * v2[0] - v1[0] * v2[2], v1[0] * v2[1] - v1[1] * v2[0]);
      }
      
      static void nor(List<double> v)
      {
        double length2 = len2(v[0], v[1], v[2]); 
        if (length2 == 0 || length2 == 1) return;
        v[0] /= Math.sqrt(length2);
        v[1] /= Math.sqrt(length2);
        v[2] /= Math.sqrt(length2);
      }
    }


     class Matrix4 {
      /** XX: Typically the unrotated X component for scaling, also the cosine of the angle when rotated on the Y and/or Z axis. On
       * Vector3 multiplication this value is multiplied with the source X component and added to the target X component. */
       static final int M00 = 0;
      /** XY: Typically the negative sine of the angle when rotated on the Z axis. On Vector3 multiplication this value is multiplied
       * with the source Y component and added to the target X component. */
       static final int M01 = 4;
      /** XZ: Typically the sine of the angle when rotated on the Y axis. On Vector3 multiplication this value is multiplied with the
       * source Z component and added to the target X component. */
       static final int M02 = 8;
      /** XW: Typically the translation of the X component. On Vector3 multiplication this value is added to the target X component. */
       static final int M03 = 12;
      /** YX: Typically the sine of the angle when rotated on the Z axis. On Vector3 multiplication this value is multiplied with the
       * source X component and added to the target Y component. */
       static final int M10 = 1;
      /** YY: Typically the unrotated Y component for scaling, also the cosine of the angle when rotated on the X and/or Z axis. On
       * Vector3 multiplication this value is multiplied with the source Y component and added to the target Y component. */
       static final int M11 = 5;
      /** YZ: Typically the negative sine of the angle when rotated on the X axis. On Vector3 multiplication this value is multiplied
       * with the source Z component and added to the target Y component. */
       static final int M12 = 9;
      /** YW: Typically the translation of the Y component. On Vector3 multiplication this value is added to the target Y component. */
       static final int M13 = 13;
      /** ZX: Typically the negative sine of the angle when rotated on the Y axis. On Vector3 multiplication this value is multiplied
       * with the source X component and added to the target Z component. */
       static final int M20 = 2;
      /** ZY: Typical the sine of the angle when rotated on the X axis. On Vector3 multiplication this value is multiplied with the
       * source Y component and added to the target Z component. */
       static final int M21 = 6;
      /** ZZ: Typically the unrotated Z component for scaling, also the cosine of the angle when rotated on the X and/or Y axis. On
       * Vector3 multiplication this value is multiplied with the source Z component and added to the target Z component. */
       static final int M22 = 10;
      /** ZW: Typically the translation of the Z component. On Vector3 multiplication this value is added to the target Z component. */
       static final int M23 = 14;
      /** WX: Typically the value zero. On Vector3 multiplication this value is ignored. */
       static final int M30 = 3;
      /** WY: Typically the value zero. On Vector3 multiplication this value is ignored. */
       static final int M31 = 7;
      /** WZ: Typically the value zero. On Vector3 multiplication this value is ignored. */
       static final int M32 = 11;
      /** WW: Typically the value one. On Vector3 multiplication this value is ignored. */
       static final int M33 = 15;
      
       static void idt (List<double> val) {
        val[M00] = 1;
        val[M01] = 0;
        val[M02] = 0;
        val[M03] = 0;
        val[M10] = 0;
        val[M11] = 1;
        val[M12] = 0;
        val[M13] = 0;
        val[M20] = 0;
        val[M21] = 0;
        val[M22] = 1;
        val[M23] = 0;
        val[M30] = 0;
        val[M31] = 0;
        val[M32] = 0;
        val[M33] = 1;
    }
      
      /** Sets the matrix to a look at matrix with a direction and an up vector. Multiply with a translation matrix to get a camera
       * model view matrix.
       * 
       * @param direction The direction vector
       * @param up The up vector
       * @return This matrix for the purpose of chaining methods together. */
       static List<double> setToLookAt (List<double> direction, List<double> up) {
          List<double> l_vez = new List<double>(3);
          List<double> l_vex = new List<double>(3);
          List<double> l_vey = new List<double>(3);
          Vector3.set(l_vez, direction);
          Vector3.nor(l_vez);
          Vector3.set(l_vex, up);
//          Vector3.nor(l_vex);
          Vector3.crs(l_vex, direction);
          Vector3.nor(l_vex);
          Vector3.set(l_vey, l_vez);
          Vector3.crs(l_vey, l_vex);
          Vector3.nor(l_vey);
          List<double>val = [1, 0, 0, 0,  0, 1, 0, 0,  0, 0, 1, 0,  0, 0, 0, 1];
          idt(val);
          val[M00] = l_vex[0];
          val[M01] = l_vex[1];
          val[M02] = l_vex[2];
          val[M10] = l_vey[0];
          val[M11] = l_vey[1];
          val[M12] = l_vey[2];
          val[M20] = l_vez[0];
          val[M21] = l_vez[1];
          val[M22] = l_vez[2];
          return val;
      }
    }







/*******************************************************************************
 * Copyright 2011 See AUTHORS file.
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *   http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 ******************************************************************************/

//package com.badlogic.gdx.math;

//import java.util.Random;

/** Utility and fast math functions.
 * <p>
 * Thanks to Riven on JavaGaming.org for the basis of sin/cos/atan2/floor/ceil.
 * @author Nathan Sweet */
 class MathUtils {
    static  final double nanoToSec = 1 / 1000000000;

    // ---
    static  final double double_ROUNDING_ERROR = 0.000001; // 32 bits
    static  final double PI = 3.1415927;
    static  final double PI2 = PI * 2;

    static  final double E = 2.7182818;

    static /*private*/ final int SIN_BITS = 14; // 16KB. Adjust for accuracy.
    static /*private*/ final int SIN_MASK = ~(-1 << SIN_BITS);
    static  /*private*/ final int SIN_COUNT = SIN_MASK + 1;

    static /*private*/ final double radFull = PI * 2;
    static /*private*/ final double degFull = 360;
    static /*private*/ final double radToIndex = SIN_COUNT / radFull;
    static /*private*/ final double degToIndex = SIN_COUNT / degFull;

    /** multiply by this to convert from radians to degrees */
    static final double radiansToDegrees = 180 / PI;
    static  final double radDeg = radiansToDegrees;
    /** multiply by this to convert from degrees to radians */
    static  final double degreesToRadians = PI / 180;
    static  final double degRad = degreesToRadians;

    // static /*private*/ class Sin {
    //     static final double[] table = new double[SIN_COUNT];
    //     static {
    //         for (int i = 0; i < SIN_COUNT; i++)
    //             table[i] = Math.sin((i + 0.5f) / SIN_COUNT * radFull);
    //         for (int i = 0; i < 360; i += 90)
    //             table[(int)(i * degToIndex) & SIN_MASK] = Math.sin(i * degreesToRadians);
    //     }
    // }

    // /** Returns the sine in radians from a lookup table. */
    // static  double sin (double radians) {
    //     return Sin.table[(int)(radians * radToIndex) & SIN_MASK];
    // }

    // /** Returns the cosine in radians from a lookup table. */
    // static  double cos (double radians) {
    //     return Sin.table[(int)((radians + PI / 2) * radToIndex) & SIN_MASK];
    // }

    // /** Returns the sine in radians from a lookup table. */
    // static  double sinDeg (double degrees) {
    //     return Sin.table[(int)(degrees * degToIndex) & SIN_MASK];
    // }

    // /** Returns the cosine in radians from a lookup table. */
    // static  double cosDeg (double degrees) {
    //     return Sin.table[(int)((degrees + 90) * degToIndex) & SIN_MASK];
    // }

    // ---

    static /*private*/ final int ATAN2_BITS = 7; // Adjust for accuracy.
    static /*private*/ final int ATAN2_BITS2 = ATAN2_BITS << 1;
    static /*private*/ final int ATAN2_MASK = ~(-1 << ATAN2_BITS2);
    static /*private*/ final int ATAN2_COUNT = ATAN2_MASK + 1;
    static final int ATAN2_DIM = Math.sqrt(ATAN2_COUNT) as int;
    static /*private*/ final double INV_ATAN2_DIM_MINUS_1 = 1.0 / (ATAN2_DIM - 1);

    // static /*private*/ class Atan2 {
    //     static final double[] table = new double[ATAN2_COUNT];
    //     static {
    //         for (int i = 0; i < ATAN2_DIM; i++) {
    //             for (int j = 0; j < ATAN2_DIM; j++) {
    //                 double x0 = i / ATAN2_DIM;
    //                 double y0 = j / ATAN2_DIM;
    //                 table[j * ATAN2_DIM + i] = Math.atan2(y0, x0);
    //             }
    //         }
    //     }
    // }

    // /** Returns atan2 in radians from a lookup table. */
    static double atan2 (double y, double x) {
      return Math.atan2(y, x);
    //     double add, mul;
    //     if (x < 0) {
    //         if (y < 0) {
    //             y = -y;
    //             mul = 1;
    //         } else
    //             mul = -1;
    //         x = -x;
    //         add = -PI;
    //     } else {
    //         if (y < 0) {
    //             y = -y;
    //             mul = -1;
    //         } else
    //             mul = 1;
    //         add = 0;
    //     }
    //     double invDiv = 1 / ((x < y ? y : x) * INV_ATAN2_DIM_MINUS_1);

    //     if (invDiv == double.POSITIVE_INFINITY) return (Math.atan2(y, x) + add) * mul;

    //     int xi = (int)(x * invDiv);
    //     int yi = (int)(y * invDiv);
    //     return (Atan2.table[yi * ATAN2_DIM + xi] + add) * mul;
    }

    // ---

//    static public Random random = new RandomXS128();
//
//    /** Returns a random number between 0 (inclusive) and the specified value (inclusive). */
//    static public int random (int range) {
//        return random.nextInt(range + 1);
//    }
//
//    /** Returns a random number between start (inclusive) and end (inclusive). */
//    static public int random (int start, int end) {
//        return start + random.nextInt(end - start + 1);
//    }
//
//    /** Returns a random number between 0 (inclusive) and the specified value (inclusive). */
//    static public long random (long range) {
//        return (long)(random.nextDouble() * range);
//    }
//
//    /** Returns a random number between start (inclusive) and end (inclusive). */
//    static public long random (long start, long end) {
//        return start + (long)(random.nextDouble() * (end - start));
//    }
//
//    /** Returns a random boolean value. */
//    static public boolean randomBoolean () {
//        return random.nextBoolean();
//    }
//
//    /** Returns true if a random value between 0 and 1 is less than the specified value. */
//    static public boolean randomBoolean (double chance) {
//        return MathUtils.random() < chance;
//    }
//
//    /** Returns random number between 0.0 (inclusive) and 1.0 (exclusive). */
//    static public double random () {
//        return random.nextdouble();
//    }
//
//    /** Returns a random number between 0 (inclusive) and the specified value (exclusive). */
//    static public double random (double range) {
//        return random.nextdouble() * range;
//    }
//
//    /** Returns a random number between start (inclusive) and end (exclusive). */
//    static public double random (double start, double end) {
//        return start + random.nextdouble() * (end - start);
//    }
//
//    /** Returns -1 or 1, randomly. */
//    static public int randomSign () {
//        return 1 | (random.nextInt() >> 31);
//    }
//
//    /** Returns a triangularly distributed random number between -1.0 (exclusive) and 1.0 (exclusive), where values around zero are
//     * more likely.
//     * <p>
//     * This is an optimized version of {@link #randomTriangular(double, double, double) randomTriangular(-1, 1, 0)} */
//    public static double randomTriangular () {
//        return random.nextdouble() - random.nextdouble();
//    }
//
//    /** Returns a triangularly distributed random number between {@code -max} (exclusive) and {@code max} (exclusive), where values
//     * around zero are more likely.
//     * <p>
//     * This is an optimized version of {@link #randomTriangular(double, double, double) randomTriangular(-max, max, 0)}
//     * @param max the upper limit */
//    public static double randomTriangular (double max) {
//        return (random.nextdouble() - random.nextdouble()) * max;
//    }
//
//    /** Returns a triangularly distributed random number between {@code min} (inclusive) and {@code max} (exclusive), where the
//     * {@code mode} argument defaults to the midpoint between the bounds, giving a symmetric distribution.
//     * <p>
//     * This method is equivalent of {@link #randomTriangular(double, double, double) randomTriangular(min, max, (max - min) * .5f)}
//     * @param min the lower limit
//     * @param max the upper limit */
//    public static double randomTriangular (double min, double max) {
//        return randomTriangular(min, max, min + (max - min) * 0.5f);
//    }
//
//    /** Returns a triangularly distributed random number between {@code min} (inclusive) and {@code max} (exclusive), where values
//     * around {@code mode} are more likely.
//     * @param min the lower limit
//     * @param max the upper limit
//     * @param mode the point around which the values are more likely */
//    public static double randomTriangular (double min, double max, double mode) {
//        double u = random.nextdouble();
//        double d = max - min;
//        if (u <= (mode - min) / d) return min + Math.sqrt(u * d * (mode - min));
//        return max - Math.sqrt((1 - u) * d * (max - mode));
//    }

    // ---

    /** Returns the next power of two. Returns the specified value if the value is already a power of two. */
    static  int nextPowerOfTwo (int value) {
        if (value == 0) return 1;
        value--;
        value |= value >> 1;
        value |= value >> 2;
        value |= value >> 4;
        value |= value >> 8;
        value |= value >> 16;
        return value + 1;
    }

    static  bool isPowerOfTwo (int value) {
        return value != 0 && (value & value - 1) == 0;
    }

    // ---

    // static  short clamp (short value, short min, short max) {
    //     if (value < min) return min;
    //     if (value > max) return max;
    //     return value;
    // }

    // static  int clamp (int value, int min, int max) {
    //     if (value < min) return min;
    //     if (value > max) return max;
    //     return value;
    // }

    // static  long clamp (long value, long min, long max) {
    //     if (value < min) return min;
    //     if (value > max) return max;
    //     return value;
    // }

    // static  double clamp (double value, double min, double max) {
    //     if (value < min) return min;
    //     if (value > max) return max;
    //     return value;
    // }

    static  double clamp (double value, double min, double max) {
        if (value < min) return min;
        if (value > max) return max;
        return value;
    }

    // ---

    /** Linearly interpolates between fromValue to toValue on progress position. */
    static  double lerp (double fromValue, double toValue, double progress) {
        return fromValue + (toValue - fromValue) * progress;
    }

    // ---

    static /*private*/ final int BIG_ENOUGH_INT = 16 * 1024;
    static /*private*/ final double BIG_ENOUGH_FLOOR = BIG_ENOUGH_INT as double;
    static /*private*/ final double CEIL = 0.9999999;
    static /*private*/ final double BIG_ENOUGH_CEIL = 16384.999999999996;
    static /*private*/ final double BIG_ENOUGH_ROUND = BIG_ENOUGH_INT + 0.5;

    // /** Returns the largest integer less than or equal to the specified double. This method will only properly floor doubles from
    //  * -(2^14) to (double.MAX_VALUE - 2^14). */
    // static  int floor (double value) {
    //     return (int)(value + BIG_ENOUGH_FLOOR) - BIG_ENOUGH_INT;
    // }

    // /** Returns the largest integer less than or equal to the specified double. This method will only properly floor doubles that are
    //  * positive. Note this method simply casts the double to int. */
    // static  int floorPositive (double value) {
    //     return (int)value;
    // }

    // /** Returns the smallest integer greater than or equal to the specified double. This method will only properly ceil doubles from
    //  * -(2^14) to (double.MAX_VALUE - 2^14). */
    // static  int ceil (double value) {
    //     return (int)(value + BIG_ENOUGH_CEIL) - BIG_ENOUGH_INT;
    // }

    // /** Returns the smallest integer greater than or equal to the specified double. This method will only properly ceil doubles that
    //  * are positive. */
    // static  int ceilPositive (double value) {
    //     return (int)(value + CEIL);
    // }

    // /** Returns the closest integer to the specified double. This method will only properly round doubles from -(2^14) to
    //  * (double.MAX_VALUE - 2^14). */
    // static  int round (double value) {
    //     return (int)(value + BIG_ENOUGH_ROUND) - BIG_ENOUGH_INT;
    // }

    // /** Returns the closest integer to the specified double. This method will only properly round doubles that are positive. */
    // static  int roundPositive (double value) {
    //     return (int)(value + 0.5f);
    // }

    /** Returns true if the value is zero (using the default tolerance as upper bound) */
    static  bool isZero (double value) {
        return (value).abs() <= double_ROUNDING_ERROR;
    }

    /** Returns true if the value is zero.
     * @param tolerance represent an upper bound below which the value is considered zero. */
    static  bool isNearZero (double value, double tolerance) {
        return (value).abs() <= tolerance;
    }

    /** Returns true if a is nearly equal to b. The function uses the default doubleing error tolerance.
     * @param a the first value.
     * @param b the second value. */
    static  bool isEqual (double a, double b) {
        return (a - b).abs() <= double_ROUNDING_ERROR;
    }

    /** Returns true if a is nearly equal to b.
     * @param a the first value.
     * @param b the second value.
     * @param tolerance represent an upper bound below which the two values are considered equal. */
    static  bool isNearEqual (double a, double b, double tolerance) {
        return (a - b).abs() <= tolerance;
    }

    /** @return the logarithm of value with base a */
    static  double log (double a, double value) {
        return (Math.log(value) / Math.log(a));
    }

    /** @return the logarithm of value with base 2 */
    static  double log2 (double value) {
        return log(2, value);
    }
}