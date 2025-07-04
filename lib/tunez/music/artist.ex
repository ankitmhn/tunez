defmodule Tunez.Music.Artist do
  use Ash.Resource, otp_app: :tunez, domain: Tunez.Music, data_layer: AshPostgres.DataLayer

  postgres do
    table "artists"
    repo Tunez.Repo

    custom_indexes do
      # https://pganalyze.com/blog/gin-index#indexing-like-searches-with-trigrams-and-gin_trgm_ops
      index "name gin_trgm_ops", name: "artists_name_gin_index", using: "GIN"
    end
  end

  actions do
    defaults [:create, :read, :destroy]

    read :search do
      # case insensitive string
      argument :query, :ci_string do
        constraints allow_empty?: true
        default ""
      end

      filter expr(contains(name, ^arg(:query)) or contains(biography, ^arg(:query)))
    end

    update :update do
      # Because the change functionality is imperative and not data-layer-compatible
      require_atomic? false
      description "Update an artist's name and keep track of previous names"
      accept [:name, :biography]

      change Tunez.Music.Changes.UpdatePreviousNames, where: [changing(:name)]
    end

    default_accept [:name, :biography]
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
      # public field so that it is accessible when sorting
      # allows for Tunez.Music.search_artists("the", [query: [sort_input: "-name"]])
      public? true
      description "The name of the artist"
    end

    attribute :biography, :string

    attribute :previous_names, {:array, :string} do
      description "List of previous names the artist has used"
      default []
    end

    create_timestamp :inserted_at, public?: true
    update_timestamp :updated_at, public?: true
  end

  relationships do
    has_many :albums, Tunez.Music.Album do
      sort year_released: :desc
    end
  end
end
