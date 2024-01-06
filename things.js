// TODO: particle effect background
/*
- pick a random x coordinate at the bottom
  of the page
- spawn a particle (rect of a solid color) at x
- slowly send it upwards to the top of the page,
  jittering the x coordinate back and forth by
  a little bit every so often

  pretty simple...
*/
start_particle_effect();
function start_particle_effect() {
    const canvas = document.querySelector("#glcanvas");
    console.log(canvas);
    /** @type {WebGLRenderingContext2} */
    const gl = canvas.getContext("webgl2");

    if (gl === null) {
        alert("Unable to initialize WebGL. Perhaps your hardware doesn't support it :/");
        return;
    }

    gl.clearColor(1.0, 0.0, 0.0, 1.0);
    gl.clear(gl.COLOR_BUFFER_BIT);
}