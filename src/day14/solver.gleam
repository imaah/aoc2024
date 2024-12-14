import argv
import file_streams/file_stream.{type FileStream}
import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/set
import gleam/string
import gleam/yielder

type Vec2 {
  Vec2(x: Int, y: Int)
}

type Robot {
  Robot(p: Vec2, v: Vec2)
}

type Input =
  #(Vec2, List(Robot))

fn parse(line: String) -> Vec2 {
  let assert Ok(#(_, pos)) = string.split_once(string.trim(line), "=")
  let assert Ok(#(x, y)) = string.split_once(pos, ",")

  let assert Ok(x) = int.parse(x)
  let assert Ok(y) = int.parse(y)
  Vec2(x, y)
}

fn parse_line(line: String) -> Robot {
  let assert Ok(#(p, v)) = string.split_once(string.trim(line), " ")
  Robot(p: parse(p), v: parse(v))
}

fn read_lines(stream: FileStream) -> List(Robot) {
  case file_stream.read_line(stream) {
    Ok(line) -> [parse_line(line), ..read_lines(stream)]
    _ -> []
  }
}

fn get_pos_after_n(r: Robot, size: Vec2, n: Int) -> Vec2 {
  let assert Ok(x) = int.modulo(r.p.x + r.v.x * n, size.x)
  let assert Ok(y) = int.modulo(r.p.y + r.v.y * n, size.y)
  Vec2(x, y)
}

fn part_1(input: Input) -> Int {
  let mid_x = { input.0 }.x / 2
  let mid_y = { input.0 }.y / 2
  input.1
  |> list.map(fn(r) { get_pos_after_n(r, input.0, 100) })
  |> list.fold(dict.new(), fn(acc, p) {
    case p {
      Vec2(x, y) if x == mid_x || y == mid_y -> acc
      Vec2(x, y) -> {
        let key = #(x < mid_x, y < mid_y)
        dict.insert(acc, key, [p, ..result.unwrap(dict.get(acc, key), [])])
      }
    }
  })
  |> dict.fold(1, fn(acc, _, v) { acc * list.length(v) })
}

fn part_2(input: Input) -> Int {
  let robots =
    list.map(input.1, fn(r) { Robot(..r, p: get_pos_after_n(r, input.0, 7520)) })

  let positions =
    list.fold(robots, set.new(), fn(acc, r) { set.insert(acc, r.p) })

  yielder.range(0, { input.0 }.y)
  |> yielder.each(fn(y) {
    list.range(0, { input.0 }.x)
    |> list.map(fn(x) {
      case set.contains(positions, Vec2(x, y)) {
        True -> "#"
        False -> "."
      }
    })
    |> string.concat()
    |> io.println
  })

  7520
}

pub fn main() {
  let filename = case argv.load().arguments {
    [filename, ..] -> filename
    _ -> "input.txt"
  }
  let assert Ok(stream) = file_stream.open_read(filename)

  let lines = case filename {
    "input.txt" | "src/day14/input.txt" -> #(Vec2(101, 103), read_lines(stream))
    _ -> #(Vec2(11, 7), read_lines(stream))
  }

  io.println("part1={" <> int.to_string(part_1(lines)) <> "}")
  io.println("part2={" <> int.to_string(part_2(lines)) <> "}")
  io.println("The part 2 will only works for my input...")
}
