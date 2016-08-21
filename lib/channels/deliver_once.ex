defmodule Channels.DeliverOnce do

    @moduledoc """
    Channel that receives a stream of data and only allows a 
    value to be transmitted once when received consecutively.
    """

    @doc """
    Input: 
      data - an enumeration of data that could be transmitted
      seen - a set of recent data items

    Output tuple:
      data - the novel data to be transmitted (not recently seen)
      seen - a new set of recent data items
    """
    def deduplicate(data, seen) do
      if Enum.empty?(data) do
        {[], MapSet.new}
      else
        data_set = MapSet.new(data)
        keep = MapSet.union(seen, data_set)
        transmit = MapSet.difference(data_set, seen)
        {MapSet.to_list(transmit), keep}
      end
    end

end
