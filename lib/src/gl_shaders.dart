import 'dart:typed_data';
import 'dart:web_gl' as webgl;
import 'dart:web_gl' show WebGL;
import 'package:tojam2020/gamegeom.dart';

abstract class GLGenericProgram
{
  webgl.RenderingContext gl;
  webgl.Program glProgram;

  void bindProgram();
  
  /**
   * Apparently, you have to disable your attributes after enabling them
   * because if you delete the arrays pointed to by attributes, it can
   * cause WebGL to fail on you.
   */
   void unbindProgram();


  static webgl.Program createShaderProgram(webgl.RenderingContext gl, String vertCode, String fragCode)
  {
    webgl.Shader vertShader = gl.createShader(WebGL.VERTEX_SHADER);
    gl.shaderSource(vertShader, vertCode);
    gl.compileShader(vertShader);
    if (!gl.getShaderParameter(vertShader, WebGL.COMPILE_STATUS))
      throw gl.getShaderInfoLog(vertShader);

    // Create a simple fragment shader
    //
    webgl.Shader fragShader = gl.createShader(WebGL.FRAGMENT_SHADER);
    gl.shaderSource(fragShader, fragCode);
    gl.compileShader(fragShader);
    if (!(gl.getShaderParameter(fragShader, WebGL.COMPILE_STATUS)))
      throw gl.getShaderInfoLog(fragShader);

    // Put the vertex shader and fragment shader together into
    // a complete program
    //
    webgl.Program shaderProgram = gl.createProgram();
    gl.attachShader(shaderProgram, vertShader);
    gl.attachShader(shaderProgram, fragShader);
    gl.linkProgram(shaderProgram);
    if (!(gl.getProgramParameter(shaderProgram, WebGL.LINK_STATUS)))
      throw gl.getProgramInfoLog(shaderProgram);
    return shaderProgram;
  }

}


class SimpleTriProgram extends GLGenericProgram
{
  webgl.UniformLocation uniTransform;
  int coordinatesVar;
  void loadUniforms(Mat4 transform)
  {
    Float32List matrix = new Float32List(16);
    for (int n = 0; n < 16; n++)
      matrix[n] = (transform.data[n]);
//    matrix.push(xScale);
//    matrix.push(0);
//    matrix.push(0);
//    matrix.push(0);
//
//    matrix.push(0);
//    matrix.push(yScale);
//    matrix.push(0);
//    matrix.push(0);
//
//    matrix.push(0);
//    matrix.push(0);
//    matrix.push(1);
//    matrix.push(0);
//    
//    matrix.push(dx);
//    matrix.push(dy);
//    matrix.push(0);
//    matrix.push(1);

    gl.useProgram(glProgram);
    gl.uniformMatrix4fv(uniTransform, false, matrix);
  }

  SimpleTriProgram(webgl.RenderingContext gl)
  {
    this.gl = gl;
    String vertCode = """
      attribute vec3 coordinates;
//      attribute vec3 colours;

      varying lowp vec3 vColours;
      //varying lowp vec4 uColor;

      uniform mat4 transformMatrix;  

      void main(void) {
        vec4 viewPos = transformMatrix * vec4(coordinates, 1.0);
        gl_Position = viewPos;
        vColours = vec3(1.0, 0.0, 0.0);
      }""";
    String fragCode = """
      varying lowp vec3 vColours;

      void main(void) {
        gl_FragColor = vec4(vColours, 1.0);
      }
    """;
    glProgram = GLGenericProgram.createShaderProgram(gl, vertCode, fragCode);
    gl.useProgram(glProgram);

    uniTransform = gl.getUniformLocation(glProgram, "transformMatrix");
    loadUniforms(Mat4.I());
    coordinatesVar = gl.getAttribLocation(glProgram, "coordinates");
    // colorsVar = gl.getAttribLocation(glProgram, "colours");
  }

  void bindProgram()
  {
    // Tell WebGL which shader program to use
    //
    gl.useProgram(glProgram);
    
    gl.enableVertexAttribArray(coordinatesVar);
    // gl.enableVertexAttribArray(colorsVar);
  }
  
  void unbindProgram()
  {
    gl.disableVertexAttribArray(coordinatesVar);
    // gl.disableVertexAttribArray(colorsVar);
  }

  TrianglesArrayBuffer createRenderableBuffer()
  {
    // Copy an array of data points forming a triangle to the
    // graphics hardware
    //
    List<double> points = [
      -0.5, -0.5, -3.0, 0.5, -0.5, -3.0, 0.5, 0.5, -3.0, 
      -0.5, -0.5, -3.0, -0.5, 0.5, -3.0, 0.5, 0.5, -3.0
    ];

    TrianglesArrayBuffer triangles = new TrianglesArrayBuffer(gl);
    triangles.buffer = gl.createBuffer();
    triangles.numTriangles = (points.length / 2) as int;
    gl.bindBuffer(WebGL.ARRAY_BUFFER, triangles.buffer);
    gl.bufferData(WebGL.ARRAY_BUFFER, Float32List.fromList(points), WebGL.STATIC_DRAW);
    return triangles;
  }

  void draw(TrianglesArrayBuffer buffer) {
        gl.bindBuffer(WebGL.ARRAY_BUFFER, buffer.buffer);

    gl.vertexAttribPointer(coordinatesVar, 3, WebGL.FLOAT, false, 12, 0);
    // gl.vertexAttribPointer(colorsVar, 3, gl.FLOAT, false, 24, 12);

    // Now we can tell WebGL to draw the triangles
    //
//    gl.activeTexture(gl.TEXTURE0);
//    gl.bindTexture(gl.TEXTURE_2D, texture);
//    gl.uniform1i(gl.getUniformLocation(glProgram, "uSampler"), 0);
    gl.drawArrays(WebGL.TRIANGLES, 0, buffer.numTriangles * 3);

  }
}


class TrianglesArrayBuffer
{
  webgl.RenderingContext gl;
  webgl.Buffer buffer;
  int numTriangles;
  
  TrianglesArrayBuffer(webgl.RenderingContext gl)
  {
    this.gl = gl;
  }
  void close()
  {
    gl.deleteBuffer(buffer);
  }
}
