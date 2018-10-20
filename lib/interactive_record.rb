require_relative "../config/environment.rb"
require 'active_support/inflector'
require 'pry'

class InteractiveRecord

  # returns table name for "self" class as a string
  def self.table_name
    self.to_s.downcase.pluralize
  end

  # returns column names for given class' table as an array of strings
  def self.column_names
    sql = "PRAGMA table_info(#{self.table_name})"
    columns_hash = DB[:conn].execute(sql)
    column_names = []
    columns_hash.each do | column |
      column_names << column["name"]
    end
    column_names
  end

  # initializes a new instance and sends each attribute from an input hash into the appropriate attr_accessor for the instance
  def initialize(props={})
    props.each do | key, value |
      self.send("#{key}=", value)
    end
  end

  # sets up a name for the table by converting class name to string (for use in SQL)
  def table_name_for_insert
    self.class.table_name
  end

  # sets up column names as a string of comma-separated column names (for use in SQL)
  def col_names_for_insert
    self.class.column_names.delete_if do | col_name |
      col_name == 'id'
    end.join(", ")
  end

  # sets up values as a string of comma-separated strings (for use with SQL VALUES keyword)
  def values_for_insert
    values = []
    self.class.column_names.each do | col_name |
      values << "'#{send(col_name)}'" unless send(col_name).nil?
    end
    values.join(", ")
  end

  # uses absracted table name, column names, and values to save a new instance to the DB, return id back to the instance object
  def save
    sql = <<-SQL
      INSERT INTO #{self.table_name_for_insert} (#{self.col_names_for_insert})
      VALUES (#{self.values_for_insert})
    SQL

    DB[:conn].execute(sql)

    sql = <<-SQL
      SELECT last_insert_rowid() FROM #{self.table_name_for_insert}
    SQL
    self.id = DB[:conn].execute(sql)[0][0]
  end

  def self.find_by_name(name)
    sql = <<-SQL
      SELECT * FROM #{self.table_name} WHERE name = ?
    SQL

    DB[:conn].execute(sql, name)
  end

  def self.find_by(attribute={})
    sql = <<-SQL
      SELECT * FROM #{self.table_name} WHERE #{attribute.keys[0]} = ?
    SQL

    DB[:conn].execute(sql, attribute.values[0])
  end

end
