defmodule CoastSnap.Resources.YodaRequest do

    use Ecto.Schema
    import Ecto.Changeset

    embedded_schema do
        field :email, :string
        field :password, :string
        field :start_date, :date
        field :end_date, :date
    end

    def changeset(request_params, params \\ %{}) do
        request_params
        |> cast(params, [:email, :password, :start_date, :end_date])
        |> validate_required([:email, :password, :start_date, :end_date])
    end

end
