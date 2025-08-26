title="Exploring optional types in C"
desc="Some things work, but None are great"
-
After an extended hiatus from the dusty old thing, I've recently found my way back to writing C. With Zig having been my language of choice, I do miss many of the creature comforts it afforded me; one such comfort being optional types. Briefly, an optional type can be *nothing* or *something*. It's sort of like how a pointer can be null or initialized, sans the memory safety implications. They're quite useful when, say, a function may or may not return a value. Or when a variable may or may not be initialized in a given block. Here's a small example (in Zig):
```
// `?` denotes an optional type.
fn lookForThing(things: []Thing, thing: Thing) ?Thing {
    var found_thing: ?Thing = null;
    for (things) |item| {
        if (item == thing) {
            found_thing = item;
            break;
        }
    }
    return found_thing;
}
```
In the above code, `found_thing` may or may not end up initialized by the time it's being returned. Therefore, it makes sense to declare it as optional. Optionals have other use cases, such as in function parameters, but there's no need to enumerate them all here. In any case, my unsatiated palate has left me with a question: might it be possible, through some anachronistic witchcraft, to bring this concept back to C?  

Well, sort of. Let's explore some of our options (no pun intended).

## The First Approach
What kind of data structure should represent an optional type? Hmm... well, we only have two pieces of relevant data: a value, and whether or not that value is initialized or uninitialized (i.e. something or nothing). That'll be our struct, then:
```
typedef struct {
    int val;
    bool is_none;
} Optional;
```
Seeing as we'll probably want to store more than just optional `int`s, let's define a macro to automagically create typed variants of such a struct:
```
#define DEFINE_OPTIONAL(type) \
    typedef struct {          \
        type val;             \
        bool is_none;         \
    } Optional_##type;
```
In case you're unfamiliar, that `##` is the *concatenation* operator of the C preprocessor. It essentially pastes the right-side operand into the source code for us. Let's redefine that optional integer type using our fancy new macro:
```
// The resulting type will be called `Optional_int`
DEFINE_OPTIONAL(int)
```
Finally, to make this thing really shine, let's define a few more macros:
```
// Returns a type's optional typename.
#define Optional(type) Optional_##type
// Populates an optional type with `value`.
#define Some(type, value) (Optional(type)){.val = (type)value, .is_none = false}
// Returns an optional with a "none" value.
#define None(type) (Optional(type)){.is_none = true}
```
Now our usage looks something like this:
```
Optional(int) maybe_int = None(int);
if (maybe_int.is_none)
    printf("I've got nothing!\n");

maybe_int = Some(int, 5);
if (!maybe_int.is_none)
    printf("I've got %d!\n", maybe_int.val);

// Output:
// I've got nothing!
// I've got 5!
```
While all might look well here, we've actually just run into a few problems. Our first problem is subtle, but is more than capable of grinding the compiler to a halt.

### `typedef` Ruins the Day
Our optional types assume that every type in a program only has *one name*. Because our `DEFINE_OPTIONAL` macro names its structs using the *exact* type name we provide, any `typedef`s of that type cannot be used with the `Optional` macro:
```
DEFINE_OPTIONAL(int)
typedef int Integer;

void some_func() {
    // Compiler error: type "Optional_Integer" is undefined
    Optional(Integer) maybe_int = Some(Integer, 100);
}
```
While this may not be a problem for individual projects which can regulate their type-naming conventions, it does pose a problem for any *default* optional types that our hypothetical library may want to define. Additionally, this macro only works for typenames with no spaces. So if you want to define an `unsigned long long`, you're *required* to use `uint64_t` or another `typedef` for it. Ultimately, the choice would be between having users redefine types using their preferred names, or having them to define every optional type themselves. Neither are particularly convenient.

### Repeating myself, repeating myself
Our next problem is, again, one of convenience. Notice how we have to provide a type to the `Some` and `None` macros?
```
Optional(int) maybe_int = Some(int, 100);
maybe_int = None(int);
```
This is both redundant, and creates more possibility for programmer error. But the worst news is that, as far as I can tell, there's no way around it. This is due to the syntax of [compound literals](https://en.cppreference.com/w/c/language/compound_literal.html). C doesn't allow you to reassign a struct inline like this:
```
MyStruct some_struct = {};
some_struct = {.field1 = 0, .field2 = "something"};
```
Rather, we must prefix the type to the struct:
```
some_struct = (MyStruct){.field1 = 0, .field2 = "something"};
```
This means that we must somehow get the type of the value we want to assign. One might think that `typeof`, recently standardized in C23, would provide an easy solution:
```
#define Some(value) \
    (Optional(typeof(value))){.val = (typeof(value))value, .is_none = false}
```
Unfortunately, it simply doesn't work like this. `typeof` is evaluated at compile-time, whereas macros are expanded *before* compile-time (at pre-processing time). This then, just produces a compiler error:
```
error: implicit declaration of function 'Optional_typeof' [-Wimplicit-function-declaration]
      | #define Optional(type) Optional_##type
      |                        ^~~~~~~~~
```
Modern C isn't done quite yet, though. C11's `_Generic` keyword can *sort of* solve our problem:
```
#define Some(value)                                                \
    _Generic((value),                                              \
        int: (Optional(int)){.val = (int)value, .is_none = false}, \
        ...                                                        \
    )
```
This would, however, require users to redefine our macros if they wanted to use them with any of their own types. From a library author's perspective, this is not preferable.

## The Only Approach
It seems, then, that we're stuck with our clunky syntax. Ruling out the possibility of storing every value behind a pointer, I'm not sure how to craft a more ergonomic approach. For the time being, my utility library ([fiesta](https://github.com/tjk113/fiesta)) will be using a design similar to what I've laid out in this article. Perhaps I'll discover some ways to optimize it in the future.