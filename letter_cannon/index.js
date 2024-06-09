class Vec2 {
    constructor(x, y) {
        this.x = x;
        this.y = y;
    }
}

const deceleration = new Vec2(0.04, 0.02);
const start_velocity = new Vec2(3.5, 0.2);
const width = window.innerWidth;
const height = window.innerHeight;
const start_position = new Vec2(width * 0.10, height / 2);
// Constants for the quadratic function
// ====================================
/* In the mathematical definition of the function,
`a` < 0 indicates that the vertex is a maximum, and
`a` > 1 indicates that the vertex is a minimum. Due
to the inversed coordinate system of the browser
window, though, `a` too must be inverted. Therefore,
the inverse is true for the aforementioned statements. */
// TODO: this is not an appropriate adjustment by resolution!
const a = 0.0008 / (width * 0.00077);
const vertex = new Vec2((width / 2) + width * 0.10, height / 4);

let letters = Array();

/**
 * Finds `y` for the given `x` on the graph of
 * the function:
 * 
 * *f(x) = a(x − h)^2 + k*
 * 
 * @param x the x coordinate
 * @param a a constant
 * @param vertex a new Vec2 of the parabola's vertex coordinates (h,k)
 * @returns the y coordinate (on the graph of the
 * quadratic function) of the given x coordinate
 */
function quadratic(x, a, vertex) {
    return a * Math.pow(x - vertex.x, 2) + vertex.y;
}

class Letter {
    constructor(character) {
        this.position = structuredClone(start_position);
        this.velocity = structuredClone(start_velocity);

        this.element = document.createElement("div");
        this.element.classList.add("letter");
        this.element.innerHTML = character;
        this.element.style.left = String(this.position.x);
        this.element.style.top = String(this.position.y);
    }

    // update_velocity() {
    //     this.velocity.x -= this.velocity.x * deceleration.x;
    //     this.velocity.y -= this.velocity.y * deceleration.y;
    // }

    move() {
        // this.update_velocity();
        const x_offset = 25;
        this.position.x += x_offset; // * this.velocity.x;
        this.position.y = quadratic(this.position.x, a, vertex);
        this.element.style.transform = `translate(${this.position.x}px, ${this.position.y}px)`;
    }
}

function remove_letter(index) {
    // Remove element from the DOM
    letters[index].element.remove();
    // Remove element from `letters`
    letters.splice(index, 1);
}

/**
 * Move letters and remove them once they're off-screen
 */
function update() {
    for (let i = 0; letters.length > 0 && i < letters.length; i++) {
        if (letters[i] != null) {
            if (letters[i].position.y >= height) {
                remove_letter(i);
                continue;
            }
            letters[i].move();
        }
    }
}

/* TODO: Display letters on `keydown`, but only
launch them on `keyup`. That way you can hold
down on the letter for a bit to have an animation
or something. */
document.addEventListener("keydown", (event) => {
    switch (event.key) {
        case "F5":
        case "F12":
        case "Shift":
            return;
        default:
            event.preventDefault();
    }
    if (event.isComposing)
        return;

    let letter = new Letter(event.key);
    letters.push(letter);
    document.body.appendChild(letter.element);
});

// https://stackoverflow.com/a/47447224
function get_random_character() {
    return String.fromCharCode(Math.floor(Math.random() * 126))
}

// Click to launch a random character (mobile friendly)
document.addEventListener("click", (event) => {
    let letter = new Letter(get_random_character());
    letters.push(letter);
    document.body.appendChild(letter.element);
});

function main_loop() {
    update();
    window.requestAnimationFrame(main_loop);
}
window.requestAnimationFrame(main_loop);