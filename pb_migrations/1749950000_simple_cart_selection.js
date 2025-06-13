/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  console.log('📦 Adding is_selected field to carts collection...');

  try {
    const collection = app.findCollectionByNameOrId("carts");
    
    if (!collection) {
      console.log('❌ Carts collection not found');
      return;
    }

    // Check if is_selected field already exists
    const hasIsSelectedField = collection.fields.some(field => field.name === 'is_selected');
    
    if (hasIsSelectedField) {
      console.log('✅ is_selected field already exists');
      return;
    }

    // Create new bool field for is_selected
    const newField = {
      "hidden": false,
      "id": "bool_is_selected_" + Date.now(),
      "name": "is_selected",
      "presentable": false,
      "required": false,
      "system": false,
      "type": "bool"
    };

    // Add the field to collection
    collection.fields.push(newField);
    
    // Save the collection
    app.save(collection);
    
    console.log('✅ Successfully added is_selected field to carts collection');

  } catch (error) {
    console.error('❌ Migration failed:', error);
  }

}, (app) => {
  console.log('🔄 Rolling back is_selected field migration...');

  try {
    const collection = app.findCollectionByNameOrId("carts");
    
    if (collection) {
      // Remove is_selected field
      const fieldIndex = collection.fields.findIndex(field => field.name === 'is_selected');
      if (fieldIndex !== -1) {
        collection.fields.splice(fieldIndex, 1);
        app.save(collection);
        console.log('✅ Successfully removed is_selected field from carts collection');
      }
    }

  } catch (error) {
    console.error('❌ Rollback failed:', error);
  }
}); 