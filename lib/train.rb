class Train
  attr_reader :id, :city_id
  attr_accessor :color 

  def initialize(attributes)
    @color = attributes.fetch(:color)
    @id = attributes.fetch(:id)
  end

  def self.all
    returned_trains = DB.exec("SELECT * FROM trains")
    trains = []
    returned_trains.each() do |train|
      color = train.fetch("color")
      id = train.fetch('id').to_i
      trains.push(Train.new({:color => color, :id => id}))
    end
    trains  
  end

  def self.clear #Just a DB.exec - don't overthink this
    DB.exec("DELETE FROM trains *;")
  end

  def self.find(id)
    train = DB.exec("SELECT * FROM trains WHERE id =#{id};").first
    color = train.fetch("color")
    id = train.fetch("id").to_i
    Train.new({:color => color, :id => id})
  end

  def save #saves name and then fetches PRIMARY KEY from db
    result = DB.exec("INSERT INTO trains (color) VALUES ('#{@color}') RETURNING id;")
    @id =result.first().fetch("id").to_i
  end

  def ==(train_to_compare)
    if train_to_compare != nil
      (self.color() == train_to_compare.color()) && (self.id() == train_to_compare.id())
    else
      false  
    end  
  end  

  def delete
    DB.exec("DELETE FROM trains WHERE id = #{@id};")
    DB.exec("DELETE FROM trains_cities WHERE train_id = #{@id};")
  end

  def update(attributes) #interfaces with forms - symbols are tied to form fields
    if (attributes.has_key?(:color)) && (attributes.fetch(:color) != nil) # keys are tethered to params from erb
      @color = attributes.fetch(:color)
      DB.exec("UPDATE trains SET color = '#{@color}' WHERE id = #{@id;};")  
    elsif (attributes.has_key?(:city_name)) && (attributes.fetch(:city_name) != nil) # has_key? is checking to see which TABLE we are looking at -- THIS IS NOT REALLY UPDATING
      city_name = attributes.fetch(:city_name)
      stop_time = attributes.fetch(:stop_time)
      city = DB.exec("SELECT * FROM cities WHERE lower(name) ='#{city_name.downcase}';").first
      if city != nil
        DB.exec("INSERT INTO trains_cities (train_id, city_id, stop_time) VALUES (#{train['id'].to_i}, #{@id}, #{stop_time});") # if city is there, do this!
      else
        city = City.new({:name => city_name, :id => nil}) # if city IS NOT there make new instance
        city.save
        DB.exec("INSERT INTO trains_cities (train_id, city_id, stop_time) VALUES (#{train['id'].to_i}, #{@id}, #{stop_time});")
      end
    end
  end

  def cities
    cities = {}
    results = DB.exec("SELECT city_id, stop_time FROM trains_cities WHERE train_id = #{@id};")
    results.each() do |result|
      city_id = result.fetch("city_id").to_i()
      stop_time = result.fetch("stop_time")
      city = DB.exec("SELECT * FROM cities WHERE id = #{city_id};")
      name = city.first().fetch("name")
      cities[stop_time] = City.new({:name => name, :id => city_id})
    end
    cities.values  
  end

end