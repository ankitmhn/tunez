defmodule TunezWeb.Albums.FormLive do
  use TunezWeb, :live_view

  def mount(%{"id" => album_id}, _session, socket) do
    album = Tunez.Music.get_album_by_id!(album_id, load: [:artist])
    # artist = Tunez.Music.get_artist_by_id!(album.artist_id)
    form = Tunez.Music.form_to_update_album(album)

    socket =
      socket
      |> assign(:form, to_form(form))
      |> assign(:artist, album.artist)
      |> assign(:page_title, "Update Album")

    {:ok, socket}
  end

  def mount(%{"artist_id" => artist_id}, _session, socket) do
    artist = Tunez.Music.get_artist_by_id!(artist_id)
    form = Tunez.Music.form_to_create_album(artist_id)

    socket =
      socket
      |> assign(:form, to_form(form))
      |> assign(:artist, artist)
      |> assign(:page_title, "New Album")

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app {assigns}>
      <.header>
        <.h1>{@page_title}</.h1>
      </.header>

      <.simple_form
        :let={form}
        id="album_form"
        as={:form}
        for={@form}
        phx-change="validate"
        phx-submit="save"
      >
        <.input name="artist_name" label="Artist" value={@artist.name} disabled />
        <%!-- <.input name="artist_id" type="hidden" value={@artist.id} /> --%>
        <div class="sm:flex gap-8 space-y-8 md:space-y-0">
          <div class="sm:w-3/4"><.input field={form[:name]} label="Name" /></div>
          <div class="sm:w-1/4">
            <.input field={form[:year_released]} label="Year Released" type="number" />
          </div>
        </div>
        <.input field={form[:cover_image_url]} label="Cover Image URL" />

        <:actions>
          <.button type="primary">Save</.button>
        </:actions>
      </.simple_form>
    </Layouts.app>
    """
  end

  def track_inputs(assigns) do
    ~H"""
    <.h2>Tracks</.h2>

    <table class="w-full">
      <thead class="border-b border-zinc-100">
        <tr>
          <th class=""></th>
          <th class="text-left font-medium text-sm pb-1 px-3">Name</th>
          <th class="text-left font-medium text-sm pb-1 px-3" colspan="2">Duration</th>
        </tr>
      </thead>
      <tbody phx-hook="trackSort" id="trackSort">
        <.inputs_for :let={track_form} field={@form[:tracks]}>
          <tr data-id={track_form.index}>
            <td class="px-3 w-20">
              <.input field={track_form[:order]} type="number" />
            </td>
            <td class="px-3">
              <label for={track_form[:name].id} class="hidden">Name</label>
              <.input field={track_form[:name]} />
            </td>
            <td class="px-3 w-36">
              <label for={track_form[:duration_seconds].id} class="hidden">Duration</label>
              <.input field={track_form[:duration_seconds]} />
            </td>
            <td class="w-12">
              <.button_link
                phx-click="remove-track"
                phx-value-path={track_form.name}
                kind="error"
                size="xs"
                inverse
              >
                <span class="hidden">Delete</span>
                <.icon name="hero-trash" class="size-5" />
              </.button_link>
            </td>
          </tr>
        </.inputs_for>
      </tbody>
    </table>

    <.button_link phx-click="add-track" kind="primary" size="sm" inverse>
      Add Track
    </.button_link>
    """
  end

  def handle_event("validate", %{"form" => form_data}, socket) do
    socket =
      socket
      |> update(:form, fn form ->
        AshPhoenix.Form.validate(form, form_data)
      end)

    {:noreply, socket}
  end

  def handle_event("save", %{"form" => form_data}, socket) do
    form_data = Map.put(form_data, "artist_id", socket.assigns.artist.id)

    case AshPhoenix.Form.submit(socket.assigns.form, params: form_data) do
      {:ok, album} ->
        socket =
          socket
          |> put_flash(:info, "Album created successfully.")
          |> push_navigate(to: ~p"/artists/#{album.artist_id}")

        {:noreply, socket}

      {:error, form} ->
        socket =
          socket
          |> assign(:form, form)
          |> put_flash(:error, "Failed to create album.")

        {:noreply, socket}
    end
  end

  def handle_event("add-track", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("remove-track", %{"path" => _path}, socket) do
    {:noreply, socket}
  end

  def handle_event("reorder-tracks", %{"order" => _order}, socket) do
    {:noreply, socket}
  end
end
