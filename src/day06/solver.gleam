import argv
import file_streams/file_open_mode
import file_streams/file_stream.{type FileStream}
import gleam/bool
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/set.{type Set}
import utils

type Pos {
  Pos(x: Int, y: Int)
}

type Input {
  Input(guard: Pos, obstructions: List(Pos), size: Pos)
}

fn read_lines(stream: FileStream, pos: Pos, input: Input) -> Input {
  case file_stream.read_chars(stream, 1) {
    Ok(".") -> read_lines(stream, Pos(pos.x + 1, pos.y), input)
    Ok("#") ->
      read_lines(
        stream,
        Pos(pos.x + 1, pos.y),
        Input(input.guard, [pos, ..input.obstructions], input.size),
      )
    Ok("^") ->
      read_lines(stream, Pos(pos.x + 1, pos.y), Input(..input, guard: pos))
    Ok("\n") ->
      read_lines(
        stream,
        Pos(0, pos.y + 1),
        Input(..input, size: Pos(pos.x, pos.y + 1)),
      )
    _ -> input
  }
}

fn same_sign(a, b: Int) -> Bool {
  int.clamp(a, -1, 1) == int.clamp(b, -1, 1)
}

fn find_in_dir(
  start: Pos,
  dir: Pos,
  obstructions: List(Pos),
) -> Result(Pos, Nil) {
  list.filter(obstructions, fn(o) {
    same_sign(o.x - start.x, dir.x) && same_sign(o.y - start.y, dir.y)
  })
  |> list.sort(fn(a, b) {
    int.compare(
      int.absolute_value({ a.x - start.x } + { a.y - start.y }),
      int.absolute_value({ b.x - start.x } + { b.y - start.y }),
    )
  })
  |> list.first()
}

fn rotate_90(dir: Pos) -> Pos {
  Pos(-dir.y, dir.x)
}

fn add_new_pos(s: Pos, e: Pos, d: Pos, v: Set(Pos)) -> Set(Pos) {
  use <- bool.guard(s.x == e.x && s.y == e.y, v)
  add_new_pos(Pos(s.x + d.x, s.y + d.y), e, d, set.insert(v, s))
}

fn visited_positions(
  start: Pos,
  dir: Pos,
  size: Pos,
  obstructions: List(Pos),
  visited: Set(Pos),
) -> Set(Pos) {
  let o = find_in_dir(start, dir, obstructions)
  case o {
    Ok(o) -> {
      let npos = Pos(o.x - dir.x, o.y - dir.y)
      visited_positions(
        npos,
        rotate_90(dir),
        size,
        obstructions,
        add_new_pos(start, npos, dir, visited),
      )
    }
    _ -> {
      let end =
        Pos(size.x * dir.x + start.x * dir.y, size.y * dir.y + start.y * dir.x)
      add_new_pos(start, end, dir, visited)
    }
  }
}

fn part_1(input: Input) -> Int {
  visited_positions(
    input.guard,
    Pos(0, -1),
    input.size,
    input.obstructions,
    set.new(),
  )
  |> set.size()
}

fn check_loop(
  start: Pos,
  dir: Pos,
  size: Pos,
  obstructions: List(Pos),
  visited: Set(#(Pos, Pos)),
) -> Bool {
  {
    use o <- result.try(find_in_dir(start, dir, obstructions))
    let npos = Pos(o.x - dir.x, o.y - dir.y)
    use <- bool.guard(set.contains(visited, #(npos, dir)), Ok(True))
    check_loop(
      npos,
      rotate_90(dir),
      size,
      obstructions,
      set.insert(visited, #(npos, dir)),
    )
    |> Ok()
  }
  |> result.unwrap(False)
}

fn part_2(input: Input) -> Int {
  visited_positions(
    input.guard,
    Pos(0, -1),
    input.size,
    input.obstructions,
    set.new(),
  )
  |> set.to_list()
  |> list.map(fn(pos) {
    use <- bool.guard(input.guard.x == pos.x && input.guard.y == pos.y, 0)
    check_loop(
      input.guard,
      Pos(0, -1),
      input.size,
      [pos, ..input.obstructions],
      set.new(),
    )
    |> bool.to_int()
  })
  |> list.fold(0, fn(acc, v) { acc + v })
}

pub fn main() {
  let filename = case argv.load().arguments {
    [filename, ..] -> filename
    _ -> "input.txt"
  }
  let assert Ok(stream) = file_stream.open(filename, [file_open_mode.Read])
  use <- utils.defer(fn() { file_stream.close(stream) })
  let lines = read_lines(stream, Pos(0, 0), Input(Pos(0, 0), [], Pos(0, 0)))

  io.println("part1={" <> int.to_string(part_1(lines)) <> "}")
  io.println("part2={" <> int.to_string(part_2(lines)) <> "}")
}
