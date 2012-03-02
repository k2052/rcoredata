module RCoreData 
  class Model  
    attr_accessor :moc, :children, :one, :many, :parent, :attributes
    
    def initialize()    
      @children   = {}
      @attributes = {}     
      @one        = {}
      @many       = {}
    end 
     
    def method_missing(method_name, *args)     
      setter = method_name.index('=')
      method_name = method_name.sub("=","")  
      
      val = args[0] if setter
          
      if @attributes.has_key?(method_name)  
        if setter
          return @moc.setValue(val, :forKey => "#{method_name}")       
        else      
          return @moc.valueForKey("#{method_name}")  
        end 
      elsif @many.has_key?(method_name) 
        if !setter       
          return @children[method_name] if @children.has_key?(method_name)
          return getChildren(method_name)    
        else   
          return false
        end
      elsif @one.has_key?(method_name)
        if !setter 
          return @children[method_name] if @children.has_key?(method_name)
          return getChild(method_name)   
        else      
          @children[method_name] = val  
          
          if val.moc.is_a?(Array) 
            return @moc.setValue(val.moc[0], :forKey => "#{method_name}")
          else             
            return @moc.setValue(val.moc, :forKey => "#{method_name}")
          end 
        end
      end          
      
      return false
    end    
    
    def save()  
      @attributes.each do |attribute, type| 
        @moc.setValue(self.send("#{attribute}"), :forKey => attribute)
      end   
                
      if @has_relationships
        @children.each do |child|
          child.save
        end  
      end    
      
      RCoreData::Model.save()
    end   
    
    def self.create(vals={})        
      name = self.to_s.gsub(/^.*::/, '')
      
      moc = NSEntityDescription.insertNewObjectForEntityForName(name,
        inManagedObjectContext:RCoreData::DataStore.moc)    
          
      entity = NSEntityDescription.entityForName(name,
        inManagedObjectContext:RCoreData::DataStore.moc)  
        
      obj = self.create_model_object(entity, moc)    
        
      attributes = entity.attributesByName()      
      
      attributes.each_pair do |attribute, value|
        obj.moc.send("#{attribute}=".to_sym, value.defaultValue)      
      end  
      
      vals.each_pair do |key, value| 
        obj.send("#{key}=", value)
      end     

      return obj
    end      
    
    def self.create_model_objects(entity, moc) 
      return false unless moc.is_a?(Array)     
      objects = []   
      
      moc.each do |moc2|         
        objects << self.create_model_object(entity, moc2)
      end  
      
      return objects
    end
    
    def self.create_model_object(entity, moc)  
      obj = self.new    
      obj.moc = moc   
            
      attributes = entity.attributesByName()      
      obj.attributes = attributes 
      
      relationships = entity.relationshipsByName       
          
      relationships.each_pair do |name, value|  
        if value.isToMany    
          obj.many[name] = value   
        else
          obj.one[name] = value
        end
      end        
            
      obj
    end
    
    def getChild(name)      
      v = @moc.valueForKey("#{name}")  
      klass = Kernel.const_get(name)   
      
      entity = NSEntityDescription.entityForName(name,
        inManagedObjectContext:RCoreData::DataStore.moc)
        
      obj     = klass.new     
      obj.moc = v     
      obj.attributes = entity.attributesByName               
      relationships = entity.relationshipsByName
      
      relationships.each_pair do |name, value|  
        if value.isToMany    
          obj.many[:name] = value   
        else
          obj.one[:name] = value
        end
      end    
      
      obj.parent = self  

      return obj
    end 
    
    def getChildren(name)    
      @moc.willAccessValueForKey("#{name}")
      v = @moc.primitiveValueForKey("#{name}")
      @moc.didAccessValueForKey("#{name}")       
      
      entity = NSEntityDescription.entityForName(name,
        inManagedObjectContext:RCoreData::DataStore.moc)

      @children[:name] = []
      v.each do |v|    
        obj = name.new    
        obj.moc        = v    
        obj.attributes = entity.attributesByName          
        relationships = entity.relationshipsByName
        
        relationships.each_pair do |name, value|  
          if value.isToMany    
            obj.many[:name] = value   
          else
            obj.one[:name] = value
          end
        end        
        
        obj.parent = self
        
        @children[:name] << obj
      end    
      
      return @children
    end    
    
    def add(name, object)   
      @moc.willAccessValueForKey("#{name}")
      v = @moc.primitiveValueForKey("#{name}")
      @moc.didAccessValueForKey("#{name}")  
       
      @moc.addObject(object.moc)  
      
      return getChildren(name)
    end
      
    def self.save()
      RCoreData::DataStore.save()
    end  
    
    def self.all()                 
      name = self.to_s.gsub(/^.*::/, '')
      
      moc    = RCoreData::DataStore.find_by_entity_name(name, 100)          
      entity = NSEntityDescription.entityForName(name,
        inManagedObjectContext:RCoreData::DataStore.moc)    

      objs = self.create_model_objects(entity, moc)     

      return objs
    end
    
    def delete()    
      RCoreData::DataStore.moc.deleteObject(@moc)
    end
  end
end