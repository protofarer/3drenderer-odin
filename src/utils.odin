package main

pr_span :: proc(msg: Maybe(string)) {
    pr("-----------------------", msg.? or_else "", "-----------------------")
}

swap :: proc {
    swap_f32,
    swap_i32,
}

swap_f32 :: proc(a: ^f32, b: ^f32) {
    tmp := a^
    a^ = b^
    b^ = tmp
}

swap_i32 :: proc(a: ^i32, b: ^i32) {
    tmp := a^
    a^ = b^
    b^ = tmp
}
