defmodule Tunez.Music.Album do
  use Ash.Resource, otp_app: :tunez, domain: Tunez.Music, data_layer: AshPostgres.DataLayer

  postgres do
    table "albums"
    repo Tunez.Repo

    references do
      # create an index on the foreign key for the relationship
      reference :artist, index?: true, on_delete: :delete
    end
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [:name, :year_released, :cover_image_url, :artist_id]
    end

    update :update do
      accept [:name, :year_released, :cover_image_url]
    end
  end

  validations do
    validate numericality(:year_released,
               greater_than_or_equal_to: 1950,
               less_than_or_equal_to: &__MODULE__.next_year/0
             ),
             where: [present(:year_released)],
             message: "Must be between 1950 and next_year inclusive "

    validate match(
               :cover_image_url,
               ~r/^(https:\/\/[^\/]+\/.*|\/images\/).*.(jpg|jpeg|png|gif)$/i
             ),
             where: [changing(:cover_image_url)],
             message:
               "Must start with 'https://' or '/images/' and end with jpg, jpeg, png, or gif"
  end

  def next_year, do: Date.utc_today().year + 1

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
    end

    attribute :year_released, :integer do
      allow_nil? false
    end

    attribute :cover_image_url, :string

    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :artist, Tunez.Music.Artist do
      allow_nil? false
      description "The artist who created the album"
    end
  end

  identities do
    identity :unique_album_names_per_artist, [:name, :artist_id],
      message: "An album with this name already exists for this artist",
      description: "Ensures that an artist cannot have two albums with the same name"
  end
end
