require 'fileutils'

module RCoreData
  class DataStore
    @@managedObjectModel         = nil
    @@managedObjectContext       = nil
    @@persistentStoreCoordinator = nil         
    @@application_support_folder = nil   

    private_class_method :new

    def self.applicationSupportFolder
      return @@application_support_folder if @@application_support_folder

      paths  = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, true)
      path   = (paths.count > 0) ? paths[0] : NSTemporaryDirectory        
      
      @@application_support_folder = File.join(path, NSApp.name.downcase)
      FileUtils.mkdir_p(@@application_support_folder) unless File.exists?(@@application_support_folder)   
      
      @@application_support_folder      
    end  
              
    def self.mom
      unless @@managedObjectModel
        model_url = NSBundle.mainBundle.URLForResource(NSApp.name, withExtension:"mom")    
        @@managedObjectModel = NSManagedObjectModel.alloc.initWithContentsOfURL(model_url)  
      end

      @@managedObjectModel    
    end            
    
    def self.managed_object_context() 
      return self.moc
    end

    def self.moc
      unless @@managedObjectContext
        coordinator = self.psc

        unless coordinator
          dict = {
            NSLocalizedDescriptionKey => "Failed to initialize the store",
            NSLocalizedFailureReasonErrorKey => "There was an error building up the data file." 
          }
          error = NSError.errorWithDomain("YOUR_ERROR_DOMAIN", code:9999, userInfo:dict)
          NSApplication.sharedApplication.presentError(error)
          return nil   
        end

        @@managedObjectContext = NSManagedObjectContext.alloc.init
        @@managedObjectContext.setPersistentStoreCoordinator(coordinator)       
      end

      @@managedObjectContext    
    end  
    
    def self.psc
      unless @@persistentStoreCoordinator
        error = Pointer.new_with_type('@')

        fileManager              = NSFileManager.defaultManager
        applicationSupportFolder = self.applicationSupportFolder

        unless fileManager.fileExistsAtPath(applicationSupportFolder, isDirectory:nil)
          fileManager.createDirectoryAtPath(applicationSupportFolder, attributes:nil)
        end

        url = NSURL.fileURLWithPath(applicationSupportFolder.stringByAppendingPathComponent("#{NSApp.name}.xml"))   
        
        @@persistentStoreCoordinator = NSPersistentStoreCoordinator.alloc.initWithManagedObjectModel(self.mom)

        unless @@persistentStoreCoordinator.addPersistentStoreWithType(NSXMLStoreType, 
          configuration:nil, 
          URL:url, 
          options:nil, 
          error:error)     
          
          NSApplication.sharedApplication.presentError(error[0])
        end 
      end

      @@persistentStoreCoordinator     
    end   
    
    def self.find_by_entity_name(entity_name, limit=25, string_or_sort_descriptor=nil, string_or_predicate=nil, *args)
      request        = NSFetchRequest.new
      request.entity = self.mom.entitiesByName[entity_name.to_sym]

      if string_or_predicate
        if string_or_predicate.is_a?(NSString)
          pred = NSPredicate.predicateWithFormat(string_or_predicate, argumentArray:args)
        elsif string_or_predicate.is_a?(NSPredicate)
          pred = string_or_predicate
        end   
      end

      if string_or_sort_descriptor
        if string_or_sort_descriptor.is_a?(NSString)
          order_by = NSSortDescriptor.alloc.initWithKey(string_or_sort_descriptor, ascending:true)
        elsif string_or_sort_descriptor.is_a?(NSSortDescriptor)
          order_by = string_or_sort_descriptor
        end  
      end
            
      request.setPredicate(pred) if pred
      request.setFetchLimit(limit) if limit
      request.sortDescriptors = [order_by] if order_by
      
      fetch_error = Pointer.new_with_type('@')
      results     = self.moc.executeFetchRequest(request, error:fetch_error)

      if ((fetch_error[0] != nil) || (results == nil))
        msg = (fetch_error[0].localizedDescription ? fetch_error[0].localizedDescription : "Unknown")
        raise "Error fetching entity #{entity_name} because #{msg}"      
      end

      return results
    end   
    
    def self.save
      error = Pointer.new_with_type('@')
      unless self.managed_object_context.save(error)
        NSApplication.sharedApplication.presentError(error[0])
      end
    end
    
    def self.should_terminate?
      reply = NSTerminateNow
      if self.managed_object_context
        if (self.managed_object_context.commitEditing)
          error = Pointer.new_with_type('@')
          if (self.managed_object_context.hasChanges and !self.managed_object_context.save(error))
            if NSApplication.sharedApplication.presentError(error[0])
              reply = NSTerminateCancel
            else
              alertReturn = NSRunAlertPanel(nil, "Could not save changes while quitting. Quit anyway?",
                                                 "Quit anyway", "Cancel", nil)
              if (alertReturn == NSAlertAlternateReturn)
                reply = NSTerminateCancel
              end
            end
          end
        else
          reply = NSTerminateCancel
        end
      end
      reply
    end
  end    
end