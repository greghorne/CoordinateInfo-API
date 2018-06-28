class CreateCoordinateInfos < ActiveRecord::Migration[5.2]
  def change
    create_table :coordinate_infos do |t|

      t.timestamps
    end
  end
end
