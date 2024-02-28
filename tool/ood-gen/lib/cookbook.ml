type task_metadata = { title : string; folder : string } [@@deriving of_yaml]

type category_metadata = {
  title : string;
  folder : string;
  tasks : task_metadata list;
}
[@@deriving of_yaml]

type category = { title : string; slug : string }
[@@deriving show { with_path = false }]

type task = { title : string; slug : string; category : category }
[@@deriving show { with_path = false }]

type code_block_with_explanation = { code : string; explanation : string }
[@@deriving of_yaml, show { with_path = false }]

type package = { name : string; version : string }
[@@deriving of_yaml, show { with_path = false }]

type metadata = {
  packages : package list;
  libraries : string list option;
  ppxes : string list option;
  code_blocks : code_block_with_explanation list;
}
[@@deriving of_yaml]

type t = {
  filepath : string;
  slug : string;
  task : task;
  packages : package list;
  libraries : string list;
  ppxes : string list;
  code_blocks : code_block_with_explanation list;
  code_plaintext : string;
  body_html : string;
}
[@@deriving
  stable_record ~version:metadata
    ~remove:[ slug; filepath; task; body_html; code_plaintext ]
    ~modify:[ code_blocks; libraries; ppxes ],
    show { with_path = false }]

let decode (tasks : task list) (fpath, (head, body)) =
  let ( let* ) = Result.bind in
  let name = Filename.basename (Filename.remove_extension fpath) in
  let category_slug = List.nth (String.split_on_char '/' fpath) 1 in
  let task_slug = List.nth (String.split_on_char '/' fpath) 2 in
  let* task =
    try Ok (tasks |> List.find (fun (c : task) -> c.slug = task_slug))
    with Not_found ->
      Error
        (`Msg
          (fpath ^ ": failed to find task '" ^ task_slug ^ "' in category "
         ^ category_slug ^ " in cookbook_categories.yml"))
  in
  let slug = String.sub name 3 (String.length name - 3) in
  let metadata = metadata_of_yaml head in

  let render_markdown str =
    str |> String.trim
    |> Cmarkit.Doc.of_string ~strict:true
    |> Hilite.Md.transform
    |> Cmarkit_html.of_doc ~safe:false
  in

  let modify_code_blocks (code_blocks : code_block_with_explanation list) =
    let code_blocks =
      code_blocks
      |> List.map (fun (c : code_block_with_explanation) ->
             let code =
               Printf.sprintf "```ocaml\n%s\n```" c.code |> render_markdown
             in
             let explanation = c.explanation |> render_markdown in
             { explanation; code })
    in
    code_blocks
  in
  let body_html = body |> render_markdown in

  Result.map
    (fun (metadata : metadata) ->
      let code_plaintext =
        metadata.code_blocks
        |> List.map (fun (c : code_block_with_explanation) -> c.code)
        |> String.concat "\n"
      in
      of_metadata ~slug ~filepath:fpath ~task ~body_html ~modify_code_blocks
        ~code_plaintext ~modify_libraries:(Option.value ~default:[])
        ~modify_ppxes:(Option.value ~default:[]) metadata)
    metadata

let all_categories_and_tasks () =
  let categories =
    Utils.yaml_sequence_file category_metadata_of_yaml
      "cookbook/cookbook_categories.yml"
  in
  let tasks = ref [] in
  let categories =
    categories
    |> List.map (fun (c : category_metadata) : category ->
           let category = { slug = c.folder; title = c.title } in
           let category_tasks =
             c.tasks
             |> List.map (fun (t : task_metadata) : task ->
                    { title = t.title; slug = t.folder; category })
           in
           tasks := category_tasks @ !tasks;
           category)
    |> List.rev
  in
  (categories, !tasks)

let all () =
  let _, tasks = all_categories_and_tasks () in
  Utils.map_files (decode tasks) "cookbook/*/*/*.md"
  |> List.sort (fun a b -> String.compare b.slug a.slug)
  |> List.rev

let template () =
  let categories, tasks = all_categories_and_tasks () in
  Format.asprintf
    {|
type category =
  { title : string
  ; slug : string
  }
type task =
  { title : string
  ; slug : string
  ; category : category
  }
type package =
  { name : string
  ; version : string
  }
type code_block_with_explanation =
  { code : string
  ; explanation : string
  }
type t =
  { slug: string
  ; filepath: string
  ; task : task
  ; packages : package list
  ; libraries : string list
  ; ppxes : string list
  ; code_blocks : code_block_with_explanation list
  ; code_plaintext : string
  ; body_html : string
  }

let categories = %a
let tasks = %a
let all = %a
|}
    (Fmt.brackets (Fmt.list pp_category ~sep:Fmt.semi))
    categories
    (Fmt.brackets (Fmt.list pp_task ~sep:Fmt.semi))
    tasks
    (Fmt.brackets (Fmt.list pp ~sep:Fmt.semi))
    (all ())