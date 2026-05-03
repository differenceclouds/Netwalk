package main

import "core:os"
import "core:fmt"
import "core:strings"
import "core:strconv"
import "vendor:curl"
import "base:runtime"

// Extracts all "style" attribute values from HTML
extract_style_attrs :: proc(html: string, allocator := context.allocator) -> [dynamic]string {
    return extract_attr_values(html, "style", allocator)
}

// Extracts a specific CSS property value from a style string
// e.g. extract_css_property("background-position: center top; color: red;", "background-position")
// returns "center top", true
extract_css_property :: proc(style: string, property: string, allocator := context.allocator) -> (string, bool) {
    search := strings.concatenate([]string{property, ":"}, context.temp_allocator)
    idx    := strings.index(style, search)
    if idx == -1 do return "", false

    rest := style[idx + len(search):]

    // Trim leading whitespace
    rest = strings.trim_left(rest, " \t")

    // Value ends at ";" or end of string
    end := strings.index(rest, ";")
    if end == -1 {
        end = len(rest)
    }

    value := strings.trim_right(rest[:end], " \t")
    return strings.clone(value, allocator), true
}

// Extracts all "style" attribute values from HTML, then finds a specific
// CSS property within each, returning the element style and extracted value as a pair
StyleResult :: struct {
    value:      string,
}

extract_css_property_from_html :: proc(html: string, css_property: string, allocator := context.allocator) -> [dynamic]StyleResult {
    results := make([dynamic]StyleResult, allocator)
    styles  := extract_style_attrs(html, context.temp_allocator)
    defer delete(styles)

    for style in styles {
        if value, ok := extract_css_property(style, css_property, allocator); ok {
            append(&results, StyleResult{
                value      = value,
            })
        }
    }
    return results
}

// ---- Reused from before ----
extract_attr_values :: proc(html: string, attr: string, allocator := context.allocator) -> [dynamic]string {
    results := make([dynamic]string, allocator)
    search  := strings.concatenate([]string{attr, `="`}, context.temp_allocator)
    rest    := html

    for {
        idx := strings.index(rest, search)
        if idx == -1 do break

        rest  = rest[idx + len(search):]
        end  := strings.index(rest, `"`)
        if end == -1 do break

        append(&results, strings.clone(rest[:end], allocator))
        rest = rest[end + 1:]
    }
    return results
}

// Converts a background-position value like "50% 100%" or "200px 400px" into a slice of i32
// Strips "%" and "px" suffixes and parses the numbers
parse_css_background_offset :: proc(value: string, allocator := context.allocator) -> [2]i32 {
    results : [2]i32
    parts   := strings.split(value, " ")
    defer delete(parts)
    for part, i in parts {
        clean := part
        clean = strings.trim_suffix(clean, "px")
        clean = strings.trim_space(clean)

        if strings.has_suffix(part, "%") do continue

        n, ok := strconv.parse_i64(clean)
        if ok {
            results[i] = i32(n)
        }
    }
    return results
}

// main :: proc() {
//     html_file, err := os.read_entire_file("daily_expert.html", context.temp_allocator)
//     if err != nil do panic("couldn't read html file")
//     html := string(html_file)

//     results := extract_css_property_from_html(html, "background-position")
//     defer delete(results)

//     if len(results) != 9*9 do panic("unexpected puzzle size")

//     offsets := make_slice([][2]i32, len(results), context.temp_allocator)
//     TILE_SIZE :: 48

//     for result, i in results {
//         offset := parse_css_background_offset(result.value)
//         offsets[i] = offset / TILE_SIZE * -1
//         fmt.println(offsets[i])
//     }
// }

main :: proc() {
    handle := curl.easy_init()
    defer curl.easy_cleanup(handle)

    builder: strings.Builder
    strings.builder_init(&builder)
    defer strings.builder_destroy(&builder)

    curl.easy_setopt(handle, .URL, "https://www.logicgamesonline.com/netwalk/daily.php")
    curl.easy_setopt(handle, .WRITEFUNCTION, write_callback)
    curl.easy_setopt(handle, .WRITEDATA, &builder)
    curl.easy_perform(handle)

    html := strings.to_string(builder)
    fmt.println(html)

    results := extract_css_property_from_html(html, "background-position")
    defer delete(results)
    // if len(results) != 9*9 do panic("unexpected puzzle size")
    offsets := make_slice([][2]i32, len(results), context.temp_allocator)
    TILE_SIZE :: 48
    for result, i in results {
        offset := parse_css_background_offset(result.value)
        offsets[i] = offset / TILE_SIZE * -1
        fmt.printf("%v\n", offsets[i])
    }
}

write_callback :: proc "c" (ptr: rawptr, size: uint, nmemb: uint, userdata: rawptr) -> uint {
    context = runtime.default_context()
    builder := cast(^strings.Builder)userdata
    data := strings.string_from_ptr(cast(^byte)ptr, cast(int)(size * nmemb))
    strings.write_string(builder, data)
    return size * nmemb
}