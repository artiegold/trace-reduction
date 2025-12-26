defmodule TicketProcessorWeb.TicketHelpers do
  @moduledoc """
  Helper functions for ticket display and formatting.
  """

  def status_color(:open), do: "blue"
  def status_color(:in_progress), do: "yellow"
  def status_color(:resolved), do: "green"
  def status_color(:closed), do: "gray"
  def status_color(:discarded), do: "red"

  def priority_color(:low), do: "gray"
  def priority_color(:medium), do: "blue"
  def priority_color(:high), do: "orange"
  def priority_color(:urgent), do: "red"

  def format_assignees([]), do: "Unassigned"
  def format_assignees([assignee]), do: assignee

  def format_assignees(assignees) when is_list(assignees) do
    "#{length(assignees)} people: #{Enum.take(assignees, 2) |> Enum.join(", ")}"
  end
end
