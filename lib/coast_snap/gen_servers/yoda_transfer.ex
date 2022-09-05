defmodule CoastSnap.GenServers.YodaClient do
    use Webdavex.Agent, base_url: "https://geo.data.uu.nl/research-coastsnap",
        hackney_options: [pool: :webdav, connect_timeout: 20_000]
end

#
# THIS MODULE ASSUMES THAT ON THE YODA SERVER A FOLDER CALLED
# "CSoutput" EXISTS!!
#

defmodule CoastSnap.GenServers.YodaTransfer do
    use GenServer
    require Logger

    alias CoastSnap.GenServers.YodaClient

    def start_link(opts) do
        GenServer.start_link(__MODULE__, opts, name: __MODULE__)
    end

    def init(_opts) do
        # start Webdav client
        { :ok, pid } = YodaClient.start_link()
        # add payload and status wrapper
        local_parent = "/home/kaand006"
        { :ok, %{ payload: [], status: :receiving, agent: pid, local_parent: local_parent } }
    end

    # question 1: can I get to the filesystem
    # question 2: can I write to Yoda

    def config_transfer(params) do
        GenServer.call(__MODULE__, { :config_transfer, params }, 30_000)
    end

    def transfer() do
        GenServer.cast(__MODULE__, :transfer)
    end

    def reset() do
        GenServer.call(__MODULE__, :reset)
    end

    def handle_call({ :config_transfer, params }, _payload, state) do
        %{ status: status, agent: agent, local_parent: local_parent } = state

        # get email and password
        username = Map.get(params, "email", "email@uu.nl")
        password = Map.get(params, "password", "secret")
        # update the client
        digest = :base64.encode(username <> ":" <> password)
        headers = [{"Authorization", "Basic " <> digest}]
        new_config = Webdavex.Config.new(
            base_url: "https://geo.data.uu.nl/research-coastsnap",
            headers: headers
        )
        # update the Agent (Webdevex is not doing this properly)
        Agent.update(agent, (fn _state -> new_config end))

        # get dates and resource type
        start_date = Map.fetch!(params, "start_date")
        end_date = Map.fetch!(params, "end_date")

        # get all files
        new_payload = filetree("#{local_parent}/CSoutput") |>
            select_resources(start_date, end_date, local_parent)

        status = case is_list(new_payload) and not(Enum.empty?(new_payload)) do
            true -> :ready
            false -> status
        end

        new_state = state
            |> Map.put(:payload, new_payload)
            |> Map.put(:status, status)

        { :reply, new_payload, new_state }
    end


    # reset payload
    def handle_call(:reset, _payload, state) do
        new_state = Map.put(state, :payload, [])
        new_state = Map.put(new_state, :status, :receiving)
        { :reply, [], new_state }
    end


    def handle_cast(:transfer, state) do
        %{ payload: payload } = state
        Enum.each(payload, fn file_object ->
            # transfer the file
            new_file_object = transfer_file(file_object)
            # check status
            status = Map.get(new_file_object, :status)
            # see if we need to create parent folders and send again
            new_file_object = if status == :http_403 do
                ensure_parent_folders(new_file_object)
                transfer_file(new_file_object)
            else
                new_file_object
            end
            Phoenix.PubSub.broadcast(
                CoastSnap.PubSub,
                "yoda",
                { :transferred, new_file_object }
            )
            new_file_object
        end)

        { :noreply, state }
    end


    # ensure parent folders on Yoda if file transfer was unsuccessful
    defp ensure_parent_folders(file_object) do
        %{ target_path: target_path } = file_object
        # first one is a blank
        [ _ | parents ] = String.split(target_path, "/")
        # and we don't want the filename
        parents = List.delete_at(parents, length(parents)-1)
        # follow folder structure from root to nested folders, and create
        # if necessary
        Enum.reduce parents, "", fn folder_name, acc ->
            target_folder = "#{acc}/#{folder_name}"
            # check if folder exists
            { _result, response } = YodaClient.head(target_folder)
            case response == :http_404 do
                true -> YodaClient.mkcol(target_folder)
                false -> :ok
            end
            target_folder
        end
        :ok
    end

    # try to transfer the file to Yoda
    defp transfer_file(file_object) do
        %{ src_path: source_path, target_path: target_path } = file_object
        # check if file exists
        { _result, response } = YodaClient.head(target_path)
        # if exists do nothing
        { _, response } = case is_list(response) do
            true -> { :ok, :already_exists }
            false -> YodaClient.put(target_path, { :file, source_path })
        end
        Map.put(file_object, :status, response)
    end


    defp filetree(dir, result \\ []) do
        Enum.reduce(File.ls!(dir), result, fn file, acc ->
            fname = "#{dir}/#{file}"
            sub_res = if File.dir?(fname), do: filetree(fname, []), else: []
            [fname] ++ sub_res ++ acc
        end)
    end


    defp select_resources(list_of_files, start_date, end_date, local_parent) do
        # convert start date to regular dates
        { :ok, start_date } = NaiveDateTime.from_iso8601(start_date <> " 00:00:00")
        { :ok, end_date } = NaiveDateTime.from_iso8601(end_date <> " 23:59:59")

        Enum.reduce(list_of_files, [], fn path, acc ->
            cond do
                File.exists?(path) ->
                    date_of_file = get_date_from_file(Path.basename(path))
                    start_comparison = NaiveDateTime.compare(start_date, date_of_file) == :lt
                    end_comparison = NaiveDateTime.compare(date_of_file, end_date) == :lt
                    if start_comparison == end_comparison do
                        target_path = String.replace(path, local_parent, "")
                        [ %{ src_path: path, target_path: target_path, type: :file, status: nil } | acc ]
                    else
                        acc
                    end
                true -> acc
            end
        end)
    end

    defp get_date_from_file(basename) do
        months = %{
            "January" => "01",
            "February" => "02",
            "March" => "03",
            "April" => "04",
            "May" => "05",
            "June" => "06",
            "July" => "07",
            "August" => "08",
            "September" => "09",
            "October" => "10",
            "November" => "11",
            "December" => "12"
        }

        try do
            parts = String.split(basename, ".")
            month = Map.fetch!(months, Enum.at(parts, 2))
            day = Enum.at(parts, 3) |> String.split("_") |> Enum.at(0)
            year = Enum.at(parts, 5) |> String.split("_") |> Enum.at(-1)
            { :ok, date } = NaiveDateTime.from_iso8601("#{year}-#{month}-#{day}" <> " 00:00:00")
            date
        rescue
            _ ->
                { :ok, date } = NaiveDateTime.from_iso8601("1900-01-01" <> " 00:00:00")
                date
        end

    end

end
