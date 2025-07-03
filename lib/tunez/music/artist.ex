defmodule Tunez.Music.Artist do
  use Ash.Resource, otp_app: :tunez, domain: Tunez.Music, data_layer: AshPostgres.DataLayer

  postgres do
    table "artists"
    repo Tunez.Repo
  end

  actions do
    defaults [:create, :read, :destroy]

    update :update do
      # Because the change functionality is imperative and not data-layer-compatible
      require_atomic? false
      description "Update an artist's name and keep track of previous names"
      accept [:name, :biography]

      change fn changeset, _context ->
               new_name = Ash.Changeset.get_attribute(changeset, :name)
               previous_name = Ash.Changeset.get_data(changeset, :name)

               previous_names = Ash.Changeset.get_data(changeset, :previous_names)

               names =
                 [previous_name | previous_names]
                 |> Enum.uniq()
                 |> Enum.reject(fn name -> name == new_name end)

               Ash.Changeset.change_attribute(changeset, :previous_names, names)
             end,
             where: [changing(:name)]
    end

    default_accept [:name, :biography]
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
      description "The name of the artist"
    end

    attribute :biography, :string

    attribute :previous_names, {:array, :string} do
      description "List of previous names the artist has used"
      default []
    end

    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  relationships do
    has_many :albums, Tunez.Music.Album do
      sort year_released: :desc
    end
  end
end
