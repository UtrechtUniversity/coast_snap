defmodule CoastSnap.Repo.Migrations.AddTermsOfAgreement do
  use Ecto.Migration

  def change do
    alter table(:snap_shots) do
        add :accepts_terms_of_agreement, :boolean, default: false
    end
  end
end
