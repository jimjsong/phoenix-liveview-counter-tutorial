defmodule LiveViewCounterWeb.Counter do
  use Phoenix.LiveView
  alias LiveViewCounter.Count
  alias Phoenix.PubSub
  alias LiveViewCounter.Presence
  alias LiveViewCounter.Cards

  @topic Count.topic
  @presence_topic "presence"

  def mount(_params, _session, socket) do
    PubSub.subscribe(LiveViewCounter.PubSub, @topic)

    Presence.track(self(), @presence_topic, socket.id, %{})
    LiveViewCounterWeb.Endpoint.subscribe(@presence_topic)


    initial_present =
      Presence.list(@presence_topic)
      |> map_size

    [top_card | cards] = Cards.create_shuffled_deck()

    {:ok, assign(socket, val: Count.current(), present: initial_present, cards: cards, top_card: top_card, card_count: length(cards)) }
  end

  def handle_event("inc", _, socket) do
    {:noreply, assign(socket, :val, Count.incr())}
  end

  def handle_event("dec", _, socket) do
    {:noreply, assign(socket, :val, Count.decr())}
  end

  def handle_event("next_card", _, %{assigns: %{cards: cards}} = socket ) do
    [next_card | new_cards] = cards
    {:noreply, assign(socket, cards: new_cards, top_card: next_card, card_count: length(new_cards))}
  end

  def handle_info({:count, count}, socket) do
    {:noreply, assign(socket, val: count)}
  end

  def handle_info(
        %{event: "presence_diff", payload: %{joins: joins, leaves: leaves}},
        %{assigns: %{present: present}} = socket
      ) do
    new_present = present + map_size(joins) - map_size(leaves)

    {:noreply, assign(socket, :present, new_present)}
  end

  def render(assigns) do
    ~L"""
    <div>
      <h1>The count is: <%= @val %></h1>
      <button phx-click="dec">-</button>
      <button phx-click="inc">+</button>
      <button phx-click="next_card">next</button>
      <h1>Current users: <%= @present %></h1>
      <h1>Current card: <%= @top_card %></h1>
      <h1>Cards Left: <%= @card_count %></h1>
    </div> .
    """
  end
end
