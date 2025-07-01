defmodule Tunez.Music.Artist do
  use Ash.Resource, otp_app: :tunez, domain: Tunez.Music, data_layer: AshPostgres.DataLayer

  postgres do
    table "artists"
    repo Tunez.Repo
  end

  actions do
    create :create do
      accept [:name, :biography]
    end

    read :read do
      # This action is the primary read action. There maybe other read actions defined later.
      # Each of the CRUD actions can have ONE primary action.
      primary? true
    end

    update :update do
      accept [:name, :biography]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
      description "The name of the artist"
    end

    attribute :biography, :string

    create_timestamp :inserted_at
    update_timestamp :updated_at
  end
end
