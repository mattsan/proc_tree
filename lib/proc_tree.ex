defmodule ProcTree do
  @moduledoc """
  Documentation for ProcTree.
  """

  def save_procs_tree(filename) do
    {:ok, io} = StringIO.open("")

    IO.puts(io, """
    graph graphname {
      rankdir=LR;
    """)

    group_leaders()
    |> Enum.each(fn group_leader ->
        Process.list()
        |> Enum.map(&%{pid: &1, info: Process.info(&1)})
        |> Enum.filter(&(&1.info[:group_leader] == group_leader))
        |> procs_to_dot(io)
      end)

    IO.puts(io, "}")

    {:ok, {_, content}} = StringIO.close(io)

    File.write(filename, content)
  end

  def procs_to_dot(procs, device \\ :stdio) do

    pids = Enum.map(procs, &(&1.pid))
    Enum.each(procs, &IO.puts(device, "  #{pid_to_nodename(&1.pid)} [width=3 label=\"#{registered_name(&1)}\", shape=box];"))

    edges =
      Enum.reduce(procs, [], fn proc, acc ->
        Enum.reduce(proc.info[:links], acc, fn link, edges ->
          if is_pid(link) && link in pids do
            edge =
              [link, proc.pid]
              |> Enum.sort()

            [edge | edges]
          else
            edges
          end
        end)
      end)

    edges
    |> Enum.uniq()
    |> Enum.sort()
    |> Enum.each(fn edge ->
        IO.puts device, "  #{edge |> Enum.map(&pid_to_nodename/1) |> Enum.join(" -- ")};"
      end)

  end

  defp group_leaders do
    Process.list()
    |> Enum.map(&(Process.info(&1)[:group_leader]))
    |> Enum.uniq()
  end

  defp registered_name(proc) do
    label = [pid_to_string(proc.pid), to_function(proc.info[:current_function])]
    case proc.info[:registered_name] do
      nil -> label
      registered_name -> [registered_name | label]
    end
    |> Enum.join("\n")
  end

  defp pid_to_string(pid) when is_pid(pid) do
    pid
    |> :erlang.pid_to_list()
    |> List.to_string()
  end

  defp pid_to_nodename(pid) when is_pid(pid) do
    pid
    |> pid_to_string()
    |> String.replace("<", "pid_")
    |> String.replace(~w(. >), "_")
  end

  defp to_function({module, function, arity}) do
    "#{inspect(module)}.#{function}/#{arity}"
  end
end
