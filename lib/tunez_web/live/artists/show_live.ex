defmodule TunezWeb.Artists.ShowLive do
  use TunezWeb, :live_view

  require Logger

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_params(%{"id" => artist_id}, _url, socket) do
    artist = Tunez.Music.get_artist_by_id!(artist_id, load: [:albums])

    socket =
      socket
      |> assign(:artist, artist)
      # |> assign(:albums, albums)
      |> assign(:page_title, artist.name)

    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app {assigns}>
      <.header>
        <.h1>
          {@artist.name}
        </.h1>
        <:subtitle :if={@artist.previous_names != []}>
          Previously known as: {@artist.previous_names |> Enum.join(", ")}
        </:subtitle>
        <:action>
          <.button_link
            kind="error"
            inverse
            data-confirm={"Are you sure you want to delete #{@artist.name}?"}
            phx-click="destroy-artist"
          >
            Delete Artist
          </.button_link>
        </:action>
        <:action>
          <.button_link navigate={~p"/artists/#{@artist.id}/edit"} kind="primary" inverse>
            Edit Artist
          </.button_link>
        </:action>
      </.header>
      <div class="mb-6">{formatted(@artist.biography)}</div>

      <.button_link navigate={~p"/artists/#{@artist.id}/albums/new"} kind="primary">
        New Album
      </.button_link>

      <ul class="mt-10 space-y-6 md:space-y-10">
        <li :for={album <- @artist.albums}>
          <.album_details album={album} />
        </li>
      </ul>
    </Layouts.app>
    """
  end

  def album_details(assigns) do
    ~H"""
    <div id={"album-#{@album.id}"} class="md:flex gap-8 group">
      <div class="mx-auto mb-6 md:mb-0 w-2/3 md:w-72 lg:w-96">
        <.cover_image image={@album.cover_image_url} />
      </div>
      <div class="flex-1">
        <.header class="pl-3 pr-2 !m-0">
          <.h2>
            {@album.name} ({@album.year_released})
          </.h2>
          <:action>
            <.button_link
              size="sm"
              inverse
              kind="error"
              data-confirm={"Are you sure you want to delete #{@album.name}?"}
              phx-click="destroy-album"
              phx-value-id={@album.id}
            >
              Delete
            </.button_link>
          </:action>
          <:action>
            <.button_link size="sm" kind="primary" inverse navigate={~p"/albums/#{@album.id}/edit"}>
              Edit
            </.button_link>
          </:action>
        </.header>
        <.track_details tracks={[]} />
      </div>
    </div>
    """
  end

  defp track_details(assigns) do
    ~H"""
    <table :if={@tracks != []} class="w-full mt-2 -z-10">
      <tr :for={track <- @tracks} class="border-t first:border-0 border-gray-100">
        <th class="whitespace-nowrap w-1 p-3">
          {String.pad_leading("#{track.order}", 2, "0")}.
        </th>
        <td class="p-3">{track.name}</td>
        <td class="whitespace-nowrap w-1 text-right p-2">{track.duration_seconds}</td>
      </tr>
    </table>
    <div :if={@tracks == []} class="p-8 text-center italic text-gray-400">
      <.icon name="hero-clock" class="w-12 h-12 bg-base-300" /> Track data coming soon....
    </div>
    """
  end

  defp formatted(nil), do: ""

  defp formatted(text) when is_binary(text) do
    text
    |> String.split("\n", trim: false)
    |> Enum.intersperse(Phoenix.HTML.raw({:safe, "<br/>"}))
  end

  def follow_toggle(assigns) do
    event =
      if assigns.on do
        JS.push("unfollow")
      else
        JS.push("follow")
        |> JS.transition("animate-spin")
      end

    assigns = assign(assigns, :event, event)

    ~H"""
    <span phx-click={@event} class="ml-3 inline-block">
      <.icon
        name={if @on, do: "hero-star-solid", else: "hero-star"}
        class="w-8 h-8 bg-yellow-400 -mt-1.5 cursor-pointer"
      />
    </span>
    """
  end

  def handle_event("destroy-artist", _params, socket) do
    IO.inspect(socket.assigns.artist, label: "Destroying artist")

    case Tunez.Music.destroy_artist(socket.assigns.artist) do
      :ok ->
        # TODO: DEBUG this. code-path doesn't work... not sure why
        socket =
          socket
          |> put_flash(:info, "Artist deleted successfully.")
          |> push_navigate(to: ~p"/")

        {:noreply, socket}

      {:error, error} ->
        Logger.info("Failed to delete artist: #{inspect(error)}")
        socket = socket |> put_flash(:error, "Failed to delete artist.")
        {:noreply, socket}
    end

    {:noreply, socket}
  end

  def handle_event("destroy-album", %{"id" => album_id}, socket) do
    case Tunez.Music.destroy_album(album_id) do
      :ok ->
        socket =
          socket
          |> update(:artist, fn artist ->
            Map.update!(artist, :albums, fn albums ->
              Enum.reject(albums, fn album -> album.id == album_id end)
            end)
          end)
          |> put_flash(:info, "Album deleted successfully.")

        {:noreply, socket}

      {:error, error} ->
        Logger.info("Failed to delete album: #{inspect(error)}")
        socket = socket |> put_flash(:error, "Failed to delete album.")
        {:noreply, socket}
    end
  end

  def handle_event("follow", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("unfollow", _params, socket) do
    {:noreply, socket}
  end
end
