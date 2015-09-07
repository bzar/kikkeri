{reverse, sum, empty, all, fold, concat-map, flatten, span, Obj, sort-by, head} = require 'prelude-ls'

# [[String]] -> Bool
in-order = (xss) -> all (-> it.length == 1), xss

# [[String] -> Data -> [[String]]] -> Data -> [String] -> [[String]]
order-by-one = (fs, d, xs) -->
  | xs.length < 2 => [xs]
  | otherwise =>
    fold ((ys, f) -> if ys.length == 1 then f(ys[0], d) else ys), [xs], fs

# [[String] -> Data -> [[String]]] -> [[String]] -> Data  -> [[String]]
order-by-many = (fs, xss, d) ->
  let yss = concat-map order-by-one(fs, d), xss
    switch
    | yss.length == xss.length => flatten yss
    | in-order yss => flatten yss
    | otherwise => order-by-many fs, yss, d

# [[String] -> Data -> [[String]]] -> [String] -> Data -> [String]
multisort = (fs, xs, d) -> order-by-many fs, [xs], d

# a -> [String] -> [[String]]
segment-by = (f, xs) -->
  | empty xs => []
  | xs.length == 1 => [xs]
  | otherwise =>
    f0 = f(head xs)
    s = span (-> f(it) == f0), xs
    [s[0]] ++ segment-by(f, s[1])


module.exports = {
  multisort
  segment-by
}

# test stuff
/*
data =
  x: {a: 1, b: 9}
  y: {a: 6, b: 6}
  z: {a: 6, b: 6}
  w: {a: 0 b: 3}
data-keys = Obj.keys data

  
sort-by-a = (xs, d) ->
  | xs.length < 2 => xs
  | otherwise => xs |> sort-by (-> d[it].a) |> segment-by (-> d[it].a)
  
sort-by-b = (xs, d) ->
  | xs.length < 2 => xs
  | otherwise => xs |> sort-by (-> d[it].b) |> segment-by (-> d[it].b)


console.log(order-by [sort-by-a, sort-by-b], data-keys, data)
  
  
  
k-data =
  x: {      y: 1, z: 1, w: 1, q: 1, goals: 50} # 4
  y: {x: 0,       z: 1, w: 0, q: 1, goals: 40} # 2
  z: {x: 0, y: 0,       w: 0, q: 1, goals: 20} # 1
  w: {x: 0, y: 1, z: 1,       q: 0, goals: 35} # 2
  q: {x: 0, y: 0, z: 0, w: 1      , goals: 30} # 1
k-data-keys = Obj.keys k-data

k-data2 =
  x: {      y: 1, z: 1, w: 0, q: 1, goals: 25} # 4
  y: {x: 0,       z: 1, w: 1, q: 0, goals: 40} # 2
  z: {x: 0, y: 0,       w: 1, q: 1, goals: 60} # 1
  w: {x: 1, y: 0, z: 0,       q: 1, goals: 30} # 2
  q: {x: 0, y: 1, z: 0, w: 1      , goals: 35} # 1
k-data2-keys = Obj.keys k-data

sort-by-score = (xs, d) ->
  scores = {[pp, (sum [s for k, s of d[pp] when k in xs])] for pp in xs}
  xs |> sort-by (-> scores[it]) |> reverse |> segment-by (-> scores[it])

sort-by-goals = (xs, d) ->
  goals = {[pp, d[pp].goals] for pp in xs}
  xs |> sort-by (-> goals[it]) |> reverse |> segment-by (-> goals[it])
  

console.log(order-by [sort-by-score, sort-by-goals], k-data-keys, k-data)

console.log(order-by [sort-by-score, sort-by-goals], k-data2-keys, k-data2)
*/
