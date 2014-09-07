defmodule Booter.Graph do

  @spec build_acyclic_graph([Booter.Step.t, ...]) :: { :ok, :digraph.graph }
  def build_acyclic_graph(steps) do
    graph = :digraph.new([:acyclic])
    try do
      for step <- steps do
        case :digraph.vertex(graph, step.name) do
          false -> :digraph.add_vertex(graph, step.name, step)
          {_, vertex} -> throw({:graph_error, {:vertex, :duplicate, step, vertex}})
        end
      end
      for step <- steps, {from, to} <- edge(step) do
        case :digraph.add_edge(graph, from, to) do
          { :error, error } -> throw({:graph_error, {:edge, error, step, from, to } })
          _ -> :ok
        end
      end
      { :ok, graph }
    catch
      { :graph_error, reason } ->
        true = :digraph.delete(graph)
        { :error, reason }
    end
  end

  defp edge(step) do
    edges = []
    edges = if step.requires, do: [{step.name, step.requires} | edges], else: edges
    if step.enables, do: [{step.enables, step.name} | edges], else: edges
  end

end
