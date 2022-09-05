defmodule CoastSnapWeb.Router do
  use CoastSnapWeb, :router

  import CoastSnapWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {CoastSnapWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :admin do
    plug :browser
    plug :put_root_layout, {CoastSnapWeb.LayoutView, :admin}
  end

  pipeline :snap do
    plug :browser
    plug :put_root_layout, {CoastSnapWeb.LayoutView, :snap}
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", CoastSnapWeb do
    pipe_through [:api]

    put "/python_ready/:id", PythonController, :update
  end

  ## Authentication routes

  scope "/", CoastSnapWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/users/register", UserRegistrationController, :new
    post "/users/register", UserRegistrationController, :create
    get "/users/log_in", UserSessionController, :new
    post "/users/log_in", UserSessionController, :create
    get "/users/reset_password", UserResetPasswordController, :new
    post "/users/reset_password", UserResetPasswordController, :create
    get "/users/reset_password/:token", UserResetPasswordController, :edit
    put "/users/reset_password/:token", UserResetPasswordController, :update
  end

  scope "/", CoastSnapWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/users/settings", UserSettingsController, :edit
    put "/users/settings", UserSettingsController, :update
    get "/users/settings/confirm_email/:token", UserSettingsController, :confirm_email
  end

  scope "/", CoastSnapWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete
  end

  scope "/admin", CoastSnapWeb.Admin do
    pipe_through [:admin, :require_authenticated_user]

    get "/", PageController, :index
    resources "/snap_shots", SnapShotController, except: [:new, :create]
    get "/snap_shots/download/:id", SnapShotController, :download
    resources "/users", UserController, only: [:index, :delete]
    put "/users/:id/confirm", UserController, :confirm
    get "/users/:id/forgot_password", UserController, :forgot_password
    resources "/pages", PageController
    resources "/uploads", UploadController, only: [:index, :create, :show, :delete]
    live "/yoda", YodaLive, :index
  end

  scope "/", CoastSnapWeb do
    pipe_through :snap

    get "/:country/:location/new", UploadController, :new
    post "/:country/:location/", UploadController, :create
  end

  scope "/", CoastSnapWeb do
    pipe_through :browser

    live "/:country/thankyou/:id", PageLive, :index
    get "/:country/:slug", VisitorController, :show
    get "/:country/", VisitorController, :index
    get "/", VisitorController, :index
  end



  # Other scopes may use custom stacks.
  # scope "/api", CoastSnapWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: CoastSnapWeb.Telemetry
    end
  end

end
