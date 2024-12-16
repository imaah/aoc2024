import argv
import file_streams/file_stream.{type FileStream}
import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string

type Element {
  Empty
  Robot
  Box(id: Int)
  Wall
}

type Vec2 {
  Vec2(x: Int, y: Int)
}

type Map =
  Dict(Vec2, Element)

type Action {
  Up
  Down
  Left
  Right
}

type Input {
  Input(map: Map, actions: List(Action))
}

fn parse_map(map: Map, stream: FileStream, y: Int) -> Map {
  case file_stream.read_line(stream) {
    Ok("\n") -> map
    Ok(line) -> {
      string.to_graphemes(string.trim(line))
      |> list.index_map(fn(v, i) {
        case v {
          "." -> Empty
          "#" -> Wall
          "O" -> Box(y * 100 + i)
          "@" -> Robot
          _ -> panic
        }
      })
      |> list.index_map(fn(v, i) { #(Vec2(x: i, y: y), v) })
      |> dict.from_list()
      |> dict.merge(map)
      |> parse_map(stream, y + 1)
    }
    _ -> panic
  }
}

fn parse_actions(stream: FileStream) -> List(Action) {
  case file_stream.read_line(stream) {
    Ok(line) -> {
      let actions =
        string.to_graphemes(string.trim(line))
        |> list.map(fn(v) {
          case v {
            ">" -> Right
            "<" -> Left
            "^" -> Up
            "v" -> Down
            _ -> panic
          }
        })

      list.flatten([actions, parse_actions(stream)])
    }
    _ -> []
  }
}

fn parse_input(stream: FileStream) -> Input {
  let map = parse_map(dict.new(), stream, 0)
  let actions = parse_actions(stream)
  Input(map: map, actions: actions)
}

fn find_robot(map: Map) -> Vec2 {
  let robot =
    dict.filter(map, fn(_, v) { v == Robot })
    |> dict.to_list()
    |> list.first()
    |> result.lazy_unwrap(fn() { panic })
  robot.0
}

fn action_to_dir(action: Action) -> Vec2 {
  case action {
    Up -> Vec2(x: 0, y: -1)
    Down -> Vec2(x: 0, y: 1)
    Left -> Vec2(x: -1, y: 0)
    Right -> Vec2(x: 1, y: 0)
  }
}

fn vec2_add(a: Vec2, b: Vec2) -> Vec2 {
  Vec2(x: a.x + b.x, y: a.y + b.y)
}

fn swap(map: Map, a: Vec2, b: Vec2) -> Map {
  map
  |> dict.insert(a, result.unwrap(dict.get(map, b), Empty))
  |> dict.insert(b, result.unwrap(dict.get(map, a), Empty))
}

fn move_box_p1(map: Map, box: Vec2, dir: Vec2) -> Result(Map, Nil) {
  let next_pos = vec2_add(box, dir)

  case dict.get(map, next_pos) {
    Ok(Empty) -> Ok(swap(map, box, next_pos))
    Ok(Box(_)) -> {
      use map <- result.try(move_box_p1(map, next_pos, dir))
      Ok(swap(map, box, next_pos))
    }
    Ok(Wall) -> Error(Nil)
    _ -> panic
  }
}

fn simulate(
  map: Map,
  actions: List(Action),
  robot: Vec2,
  move_box: fn(Map, Vec2, Vec2) -> Result(Map, Nil),
) -> Map {
  case actions {
    [first, ..rest] -> {
      let dir = action_to_dir(first)
      let next_pos = vec2_add(robot, dir)

      case dict.get(map, next_pos) {
        Ok(Wall) -> simulate(map, rest, robot, move_box)
        Ok(Empty) ->
          map
          |> swap(robot, next_pos)
          |> simulate(rest, next_pos, move_box)
        Ok(Box(_)) ->
          case move_box(map, next_pos, dir) {
            Ok(map) ->
              map
              |> swap(robot, next_pos)
              |> simulate(rest, next_pos, move_box)
            Error(_) -> simulate(map, rest, robot, move_box)
          }
        _ -> panic
      }
    }
    [] -> map
  }
}

fn is_box(e: Element) {
  case e {
    Box(_) -> True
    _ -> False
  }
}

fn part_1(input: Input, robot: Vec2) -> Int {
  simulate(input.map, input.actions, robot, move_box_p1)
  |> dict.filter(fn(_, v) { is_box(v) })
  |> dict.to_list()
  |> list.map(fn(v) { { v.0 }.x + { v.0 }.y * 100 })
  |> int.sum()
}

fn find_other_part(map: Map, box: Vec2) -> Vec2 {
  let assert Ok(Box(id)) = dict.get(map, box)
  let before = vec2_add(box, Vec2(1, 0))
  let after = vec2_add(box, Vec2(-1, 0))

  case dict.get(map, before), dict.get(map, after) {
    Ok(Box(bid)), _ if bid == id -> before
    _, Ok(Box(bid)) if bid == id -> after
    _, _ -> panic
  }
}

fn move_box_p2(map: Map, box: Vec2, dir: Vec2) -> Result(Map, Nil) {
  let other_part = find_other_part(map, box)
  let next_pos1 = vec2_add(box, dir)
  let next_pos2 = vec2_add(other_part, dir)

  use <- bool.lazy_guard(dir == Vec2(-1, 0) || dir == Vec2(1, 0), fn() {
    move_box_p1(map, box, dir)
  })
  let map = case dict.get(map, next_pos1), dict.get(map, next_pos2) {
    Ok(Empty), Ok(Empty) -> Ok(map)
    Ok(Wall), Ok(Wall) | Ok(_), Ok(Wall) | Ok(Wall), Ok(_) -> Error(Nil)
    Ok(Box(id1)), Ok(Box(id2)) if id1 != id2 -> {
      use map <- result.try(move_box_p2(map, next_pos1, dir))
      move_box_p2(map, next_pos2, dir)
    }
    Ok(Box(_)), Ok(Box(_)) -> move_box_p2(map, next_pos1, dir)
    Ok(Box(_)), Ok(_) -> move_box_p2(map, next_pos1, dir)
    Ok(_), Ok(Box(_)) -> move_box_p2(map, next_pos2, dir)
    _, _ -> panic
  }

  case map {
    Ok(map) ->
      map
      |> swap(box, next_pos1)
      |> swap(other_part, next_pos2)
      |> Ok()
    _ -> Error(Nil)
  }
}

fn scale_up(map: Map) -> Map {
  dict.fold(map, dict.new(), fn(acc, k, v) {
    case v {
      Robot ->
        acc
        |> dict.insert(Vec2(x: k.x * 2, y: k.y), Robot)
        |> dict.insert(Vec2(x: k.x * 2 + 1, y: k.y), Empty)
      v ->
        acc
        |> dict.insert(Vec2(x: k.x * 2, y: k.y), v)
        |> dict.insert(Vec2(x: k.x * 2 + 1, y: k.y), v)
    }
  })
}

fn part_2(input: Input, _: Vec2) -> Int {
  let map = scale_up(input.map)
  let robot = find_robot(map)

  simulate(map, input.actions, robot, move_box_p2)
  |> dict.filter(fn(_, v) { is_box(v) })
  |> dict.to_list()
  |> list.group(fn(v) {
    case v.1 {
      Box(id) -> id
      _ -> panic
    }
  })
  |> dict.fold(0, fn(acc, _, v) {
    acc
    + {
      let p =
        list.sort(v, fn(a, b) { int.compare({ a.0 }.x, { b.0 }.x) })
        |> list.first()
        |> result.unwrap(#(Vec2(0, 0), Box(0)))
      { p.0 }.x + 100 * { p.0 }.y
    }
  })
}

pub fn main() {
  let filename = case argv.load().arguments {
    [filename, ..] -> filename
    _ -> "input.txt"
  }
  let assert Ok(stream) = file_stream.open_read(filename)

  let input = parse_input(stream)
  let r_pos = find_robot(input.map)

  io.println("part1={" <> int.to_string(part_1(input, r_pos)) <> "}")
  io.println("part2={" <> int.to_string(part_2(input, r_pos)) <> "}")
}
