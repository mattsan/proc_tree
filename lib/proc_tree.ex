defmodule ProcTree do
  @moduledoc """
  Documentation for ProcTree.
  """

  def save_procs_tree(filename) do
    {:ok, io} = StringIO.open("")
    procs() |> procs_to_dot(io)
    {:ok, {_, content}} = StringIO.close(io)

    File.write(filename, content)
  end

  def procs_to_dot(procs, device \\ :stdio) do
    IO.puts(device, """
    graph graphname {
      rankdir=LR;
    """)

    Enum.each(procs, &IO.puts(device, "  #{pid_to_nodename(&1.pid)} [width=3 label=\"#{&1.registered_name}\", shape=box];"))

    edges =
      Enum.reduce(procs, [], fn proc, acc ->
        Enum.reduce(proc.links, acc, fn link, edges ->
          edge =
            [link, proc.pid]
            |> Enum.sort()

          [edge | edges]
        end)
      end)

    edges
    |> Enum.uniq()
    |> Enum.sort()
    |> Enum.each(fn edge ->
        IO.puts device, "  #{edge |> Enum.map(&pid_to_nodename/1) |> Enum.join(" -- ")};"
      end)

    IO.puts(device, "}")
  end

  def procs do
    Process.list()
    |> Enum.filter(&Process.alive?/1)
    |> Enum.map(&graph_info/1)
  end

  defp graph_info(pid) do
    info = Process.info(pid)
    registered_name = info[:registered_name] || pid_to_string(pid)
    group_leader = pid_to_nodename(info[:group_leader])
    links = info[:links] |> Enum.filter(&is_pid/1)

    %{
      pid: pid,
      registered_name: registered_name,
      group_leader: group_leader,
      links: links
    }
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
end
