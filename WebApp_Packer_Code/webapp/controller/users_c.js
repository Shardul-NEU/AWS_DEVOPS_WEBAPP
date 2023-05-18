import { db } from "../index.js";
import bcrypt from 'bcrypt';
import auth from 'basic-auth';
import AWS from 'aws-sdk';
import {logger} from '../index.js';
import {logAPICall} from '../index.js';


//import express from 'express';
//import bodyParser from 'body-parser';
const saltRounds = 10;
//import mysql from 'mysql2';

//login function
export const login = (req, res) => {
    const { email, password } = req.body;
    db.query("SELECT * FROM users WHERE email = ?", [email], (error, result) => {
      if (error) {
        res.status(500).send({ message: "Internal server error" });
        return;
      }
      if (result.length > 0) {
        const user = result[0];
        bcrypt.compare(password, user.password, (err, match) => {
          if (err) {
            res.status(500).send({ message: "Internal server error" });
            return;
          }
          if (match) {
            res.send({
              message: "Login successful!",
              userId: user.id
            });
          } else {
            res.status(401).send({ message: "Incorrect email or password" });
          }
        });
      } else {
        res.status(401).send({ message: "Incorrect email or password" });
      }
    });
  };


//return  user

export const getuser = (req, res) => {
  logger.info("Get user API called");
  logAPICall('get_User_API');
    // First, extract the username and password from the headers
    const credentials = auth(req);
    
    // If the credentials are missing or invalid, return an error
    if (!credentials || !credentials.name || !credentials.pass) {
    res.statusCode = 401;
    res.setHeader("WWW-Authenticate", "Basic realm='example'");
    logger.info("Satus 401 : Access denied - credentials missing or invalied");
    return res.end("Access denied");
    };
    
    // Check if the credentials are valid by comparing them with the values stored in the database
    db.query('SELECT * FROM users WHERE username = ?', [credentials.name], (error, results) => {
    if (error) {
    // If there's an error with the query, return an error
    res.statusCode = 500;
    logger.error("Status 500 : Error with a DB query")
    return res.end("Server error");
    }
    
    if (!results.length) {
      // If no matching records were found, return an error
      res.statusCode = 401;
      res.setHeader("WWW-Authenticate", "Basic realm='example'");
      logger.info("Status 401: Access denied - No matching records were found")
      return res.end("Access denied");
    }
    
    // Compare the entered password with the hashed password stored in the database
    bcrypt.compare(results[0].password,credentials.pass , (error, result) => {
      if (error) {
        // If there's an error with bcrypt, return an error
        res.statusCode = 500;
        logger.error("Status 500 : Server Error - Error with Bcrypt")
        return res.end("Server error");
      }
      
      if (result) {
        // If the passwords don't match, return an error
        res.statusCode = 401;
        res.setHeader("WWW-Authenticate", "Basic realm='example'");
        logger.info("Status 401 : Access denied - Incorrect Password")
        return res.end("Access denied");
      }
   
    db.query(
    'SELECT * FROM users WHERE username = ?',
    [credentials.name],
    (error, results) => {
    if (error) {
    return res.status(500).json({ error: error });
    }
    if (!results.length) {
    logger.info("Status 400 : User Not Found")
    return res.status(400).json({ error: 'User not found' });
    }
    const user = results[0];
    bcrypt.compare(credentials.pass, user.password, function(err, result) {
    if (err) {
    return res.status(500).json({ error: err });
    }
    if (!result) {
    return res.status(401).json({ error: 'Authorization failed' });
    }
    if (credentials.name !== user.username) {
    return res.status(401).json({ error: 'Authorization failed' });
    }
    const { password, ...userDetails } = user;
    logger.info("Status 200 : Returned user details successfully")
    return res.status(200).json({ user: userDetails });
    });
    }
    );
    }
    );}
    );}


//create user function
// export const createUser = (req, res) => {
//   logAPICall('Create_User_API');
//   logger.info("Create user API called");
//   const firstName = req.body.first_name;
//   const lastName = req.body.last_name;
//   const email = req.body.email;
//   const password = req.body.password;
//   const accountCreated = new Date().toISOString().slice(0, 19).replace('T', ' ');
  
//   db.query('SELECT * FROM users WHERE username = ?', [email], (error, results) => {
//   if (error) {
//   return res.status(500).json({ error: error.message });
//   }
//   if (results.length > 0) {
//   logger.info("Status 409 : Creation Failed - Email already exists");
//   return res.status(409).json({ error: 'Email already exists' });
//   }
//   bcrypt.hash(password, saltRounds, function (err, hash) {
//   if (err) {
//   logger.info("Status 500 : Internal Server Error")
//   return res.status(500).json({ error: err.message });
//   }
//   db.query(
//   'INSERT INTO users (first_name, last_name, username, password, account_created, account_updated) VALUES (?,?,?,?,?,NULL)',
//   [firstName, lastName, email, hash, accountCreated],
//   (error, results) => {
//   if (error) {
//   return res.status(500).json({ error: error.message });
  
//   }
//   logger.info('Status 200: User created successfully');
//   return res.status(200).json({ results: results.affectedRows });
//   }
//   );
//   });
//   });
//   };
  
export const createUser = (req, res) => {
  logAPICall('Create_User_API');
  logger.info("Create user API called");
  const firstName = req.body.first_name;
  const lastName = req.body.last_name;
  const email = req.body.email;
  const password = req.body.password;
  const accountCreated = new Date().toISOString().slice(0, 19).replace('T', ' ');
  
  db.query('SELECT * FROM users WHERE username = ?', [email], (error, results) => {
    if (error) {
      return res.status(500).json({ error: error.message });
    }
    if (results.length > 0) {
      logger.info("Status 409 : Creation Failed - Email already exists");
      return res.status(409).json({ error: 'Email already exists' });
    }
    bcrypt.hash(password, saltRounds, function (err, hash) {
      if (err) {
        logger.info("Status 500 : Internal Server Error")
        return res.status(500).json({ error: err.message });
      }
      db.query(
        'INSERT INTO users (first_name, last_name, username, password, account_created, account_updated) VALUES (?,?,?,?,?,NULL)',
        [firstName, lastName, email, hash, accountCreated],
        (error, results) => {
          if (error) {
            return res.status(500).json({ error: error.message });
          }
          const userId = results.insertId;
          db.query('SELECT id, first_name, last_name, username, account_created, account_updated FROM users WHERE id = ?', [userId], (error, results) => {
            if (error) {
              return res.status(500).json({ error: error.message });
            }
            logger.info('Status 200: User created successfully');
            const createdUser = results[0];
            return res.status(200).json({ user: createdUser });
          });
        }
      );
    });
  });
};


  //update function

export const update = (req, res) => {
  logAPICall('update_User_API');
  logger.info("Update user API called");
// First, extract the username and password from the headers
const credentials = auth(req);

// If the credentials are missing or invalid, return an error
if (!credentials || !credentials.name || !credentials.pass) {
res.statusCode = 401;
res.setHeader("WWW-Authenticate", "Basic realm='example'");
logger.info("Satus 401 : Access denied - credentials missing or invalied");
return res.end("Access denied");
};

// Check if the credentials are valid by comparing them with the values stored in the database
db.query('SELECT * FROM users WHERE username = ?', [credentials.name], (error, results) => {
if (error) {
// If there's an error with the query, return an error
res.statusCode = 500;
logger.error("Status 500: Internal Server Error")
return res.end("Server error");
}

if (!results.length) {
  // If no matching records were found, return an error
  res.statusCode = 401;
  res.setHeader("WWW-Authenticate", "Basic realm='example'");
  logger.info("Status 401 : Access denied - No matching record")
  return res.end("Access denied");
}

// Compare the entered password with the hashed password stored in the database
bcrypt.compare(credentials.pass, results[0].password, (error, result) => {
  if (error) {
    // If there's an error with bcrypt, return an error
    res.statusCode = 500;
    return res.end("Server error");
  }
  
  if (!result) {
    // If the passwords don't match, return an error
    res.statusCode = 401;
    res.setHeader("WWW-Authenticate", "Basic realm='example'");
    logger.info("Status 401 : Access denied - Incorrect password");
    return res.end("Access denied");
  }
  
  // If the credentials are valid, continue with the update process
  const userId = results[0].id;
  const { first_name, last_name, password } = req.body;
  const updateValues = {};

  // Only update the fields that were provided in the request body
  if (first_name) {
    updateValues.first_name = first_name;
  }
  if (last_name) {
    updateValues.last_name = last_name;
  }
  if (password) {
    updateValues.password = bcrypt.hashSync(password, 10);
  }
  updateValues.account_updated = new Date().toISOString().slice(0, 19).replace('T', ' ');

  // Update the values in the database
  const sql = `UPDATE users SET ? WHERE id = ?`;
  db.query(sql, [updateValues, userId], (error, results) => {
    if (error) {
      // If there's an error with the query, return an error
      res.statusCode = 500;
      return res.end("Server error");
    }

    res.statusCode = 200;
    logger.info("Status 200 : User updated successfully");
    return res.end("Update successful");
        });
    });
});

};


//add products API

export const createProduct = (req, res) => {
  logAPICall('Create_Product_API');
  logger.info("Create product API called");
  const credentials = auth(req);
  
  // If the credentials are missing or invalid, return an error
  if (!credentials || !credentials.name || !credentials.pass) {
  res.statusCode = 401;
  res.setHeader("WWW-Authenticate", "Basic realm='example'");
  logger.info("Satus 401 : Access denied - credentials missing or invalied");
  return res.end("Access denied");
  }
  
  // Check if the credentials are valid by comparing them with the values stored in the database
  db.query('SELECT * FROM users WHERE username = ?', [credentials.name], (error, results) => {
  if (error) {
  // If there's an error with the query, return an error
  res.statusCode = 500;
  return res.end("Server error");
  }
  if (!results.length) {
    // If no matching records were found, return an error
    res.statusCode = 401;
    res.setHeader("WWW-Authenticate", "Basic realm='example'");
    logger.info("Status 401 : Access denied - No matching record")
    return res.end("Access denied");
  }
  
  // Compare the entered password with the hashed password stored in the database
  bcrypt.compare(credentials.pass, results[0].password, (error, result) => {
    if (error) {
      // If there's an error with bcrypt, return an error
      res.statusCode = 500;
      return res.end("Server error");
    }
  
    if (!result) {
      // If the passwords don't match, return an error
      res.statusCode = 401;
      res.setHeader("WWW-Authenticate", "Basic realm='example'");
      logger.info("Status 401 : Access denied - Incorrect password");
      return res.end("Access denied");
    }
  
    const name = req.body.name;
    const description = req.body.description;
    const SKU = req.body.SKU;
    const manufacturer = req.body.manufacturer;
    const quantity = req.body.quantity;
    const date_added = new Date().toISOString().slice(0, 19).replace('T', ' ');
    const date_last_updated = null;
    // const owner_user_id = userResult[0].id;
    const owner_user_id = results[0].id;
    if (!name || !description || !SKU || !manufacturer || !quantity) {
      logger.info("Status 400 : Create product failed - Missing required fields")
      return res.status(400).send({ message: 'Missing required fields' });
    }
  
    if (quantity < 0) {
      logger.info("Status 400 : Create product failed - Invaied quantity provided")
      return res.status(400).send({ message: 'Invalid quantity' });
    }
  
    db.query(
      'INSERT INTO products (name, description, SKU, manufacturer, quantity, date_added, date_last_updated, owner_user_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      [name, description, SKU, manufacturer, quantity, date_added, date_last_updated, owner_user_id],
      (error, results) => {
        if (error) {
          return res.status(500).json({ error: error.message });
        }
  
        const productId = results.insertId;
        logger.info("Status 201 : Product created successfully");
        return res.status(201).send({
          message: 'Product created',
          id: productId,
          name,
          description,
          SKU,
          manufacturer,
          quantity,
          date_added,
          date_last_updated,
          owner_user_id
        });
        }
        );
        });
      });
    }

    const authenticate = (req, res, next, callback) => {
      const user = auth(req);
      if (!user || !user.name || !user.pass) {
        res.set("WWW-Authenticate", 'Basic realm="example"');
        logger.info("Status 401 : Unauthorized")
        return res.status(401).json({message: 'Unauthorized'});
      }
      const query = "SELECT * FROM users WHERE username = ?";
      db.query(query, [user.name], (error, result) => {
        if (error) {
          return res.status(401).json(error);
        }
        if (!result[0]) {
          res.set("WWW-Authenticate", 'Basic realm="example"');
          logger.info("Status 401 : Unauthorized")
          return res.status(401).json({message: 'Unauthorized'});
        }
        const password = result[0].password;
        bcrypt.compare(user.pass, password, (error, match) => {
          if (error) {
            return res.status(401).json(error);
          }
          if (!match) {
            res.set("WWW-Authenticate", 'Basic realm="example"');
            logger.info("Status 401 : Unauthorized")
            return res.status(401).json({message: 'Unauthorized'});
          }
          req.user = result[0];
          callback(null, result[0].id);
        });
      });
    };
    
    // function to delete product
    export const deleteProduct = (req, res, next) => {
      logAPICall('Delete_Product_API');
      logger.info("Delete product API called")
      authenticate(req, res, next, (error, owner_user_id) => {
        if (error) {
          return res.status(error).send();
        }
    
      const productId = req.params.productId;
      if (productId==" ") {
        logger.info("Status 400 : Delete Product failed - Missing required producct ID");
        return res.status(400).send({ message: "Missing required product ID" });
      }
    
      const query = "SELECT * FROM products WHERE id = ?";
      db.query(query, [productId], (error, result) => {
        if (error) {
          return res.status(500).send(error);
        }
        if (!result[0]) {
          logger.info("Status 404 : Delete Product failed - Product Not found");
          return res.status(404).send({ message: "Product not found" });
        }
        if (result[0].owner_user_id !== owner_user_id) {
          logger.info("Status 403 : Forbidden - Not authorized to delete this product");
          return res.status(403).send({ message: "Forbidden: Not authorized to delete this product" });
        }
        const deleteQuery = "DELETE FROM products WHERE id = ?";
        db.query(deleteQuery, [productId], (error, result) => {
          if (error) {
            return res.status(500).send(error);
          }
          logger.info("Status 204 : Product deleted successfully");
          return res.status(204).send();
        });
      });
    });
  }
  
  
  // update products code
export const updateProduct = (req, res, next) => {
  logAPICall('Update_Product_API');
  logger.info("Update product API called")
  authenticate(req, res, next, (error, owner_user_id) => {
    if (error) {
      return res.status(error).send();
    }

    const productId = req.params.productId;
    if (!productId) {
      logger.info("Status 400 : Update product failed - Missing required product ID");
      return res.status(400).send({ message: "Missing required product ID" });
    }

    const { name, description, SKU, manufacturer, quantity } = req.body;
    if (!name || !description || !SKU || !manufacturer || !quantity) {
      logger.info("Status 400 : Update product failed - Missing required fields");
      return res.status(400).send({ message: "Missing required data for product update" });
    }

    if (isNaN(quantity) || quantity < 0) {
      logger.info("Status 400 : Update product failed - Invalied quantity");
      return res.status(400).send({ message: "Invalid quantity provided" });
    }

    const checkQuery = "SELECT * FROM products WHERE id = ?";
    db.query(checkQuery, [productId], (error, result) => {
      if (error) {
        return res.status(500).send(error);
      }
      if (!result[0]) {
        logger.info("Status 404 : Update product failed - Product not found");
        return res.status(404).send({ message: "Product not found" });
      }
      if (result[0].owner_user_id !== owner_user_id) {
        logger.info("Status 403 : Forbidden - Not authorized to update this product");
        return res.status(403).send({ message: "Forbidden: Not authorized to update this product" });
      }

      const checkSKUQuery = "SELECT * FROM products WHERE SKU = ? AND id != ?";
      db.query(checkSKUQuery, [SKU, productId], (error, result) => {
        if (error) {
          return res.status(500).send(error);
        }
        if (result[0]) {
          logger.info("Status 400 : Update product failed - Product SKU already exists");
          return res.status(400).send({ message: "Product SKU already exists" });
        }

        const updateQuery = "UPDATE products SET name = ?, description = ?, SKU = ?, manufacturer = ?, quantity = ?, date_last_updated = NOW() WHERE id = ?";
        db.query(
          updateQuery,
          [name, description, SKU, manufacturer, quantity, productId],
          (error, result) => {
            if (error) {
              return res.status(500).send(error);
            }
            logger.info("Status 204 : Product updated successfully");
            return res.status(204).send({message:'No Content'});
          }
        );
      });
    });
  });
};


// update product code using patch command

export const updateProductPatch = (req, res, next) => {
  logAPICall('Update_Product_Patch_API');
  authenticate(req, res, next, (error, owner_user_id) => {
    if (error) {
      return res.status(error).send();
    }

    const productId = req.params.productId;
    if (!productId) {
      return res.status(400).send({ message: "Missing required product ID" });
    }

    const fieldsToUpdate = {};
    if (req.body.name) {
      fieldsToUpdate.name = req.body.name;
    }
    if (req.body.description) {
      fieldsToUpdate.description = req.body.description;
    }
    if (req.body.SKU) {
      fieldsToUpdate.SKU = req.body.SKU;
    }
    if (req.body.manufacturer) {
      fieldsToUpdate.manufacturer = req.body.manufacturer;
    }
    if (req.body.quantity) {
      if (isNaN(req.body.quantity) || req.body.quantity < 0) {
        return res.status(400).send({ message: "Invalid quantity provided" });
      }
      fieldsToUpdate.quantity = req.body.quantity;
    }

    const checkQuery = "SELECT * FROM products WHERE id = ?";
    db.query(checkQuery, [productId], (error, result) => {
      if (error) {
        return res.status(500).send(error);
      }
      if (!result[0]) {
        return res.status(404).send({ message: "Product not found" });
      }
      if (result[0].owner_user_id !== owner_user_id) {
        return res.status(403).send({ message: "Forbidden: Not authorized to update this product" });
      }

      if (fieldsToUpdate.SKU) {
        const checkSKUQuery = "SELECT * FROM products WHERE SKU = ? AND id != ?";
        db.query(checkSKUQuery, [fieldsToUpdate.SKU, productId], (error, result) => {
          if (error) {
            return res.status(500).send(error);
          }
          if (result[0]) {
            return res.status(400).send({ message: "Product SKU already exists" });
          }

          const updateQuery = "UPDATE products SET ?, date_last_updated = NOW() WHERE id = ?";
          db.query(updateQuery, [fieldsToUpdate, productId], (error, result) => {
            if (error) {
              return res.status(500).send(error);
            }
            return res.status(204).send({message:'No Content'});
          });
        });
      } else {
        const updateQuery = "UPDATE products SET ?, date_last_updated = NOW() WHERE id = ?";
        db.query(updateQuery, [fieldsToUpdate, productId], (error, result) => {
          if (error) {
            return res.status(500).send(error);
          }
          return res.status(204).send({message:'No Content'});
        });
      }
    });
  });
}


// function to return product details

export const returnProduct = (req, res) => {
  logAPICall('Return_Product_API');
  logger.info("Return product update API called");
  const productId = req.params.productId;

  db.query("SELECT * FROM products WHERE id = ?", [productId], (error, result) => {
  console.log(productId);
  if (result.length === 0) {
    logger.info("Status 404 : Product not found");
  return res.status(404).json({ error: 'Product not found' });
  }
  console.log(result[0]);
  logger.info("Status 200 : Product updated successfully");
  return res.status(200).json(result[0]);
});
}


// code for image operations in s3



import { v4 as uuidv4 } from 'uuid';

const s3 = new AWS.S3();

export const uploadImage = (req, res, next) => {
  logAPICall('Upload_Image_API');
  logger.info("Add image API called");
  const productId = req.params.productId;
  const file_name = req.file.originalname;
  const file_type = req.file.mimetype;
  const file_size = req.file.size;
  const file_data = req.file.buffer;
  const credentials = auth(req);

  // If the credentials are missing or invalid, return an error
  if (!credentials || !credentials.name || !credentials.pass) {
    res.statusCode = 401;
    res.setHeader("WWW-Authenticate", "Basic realm='example'");
    logger.info("Satus 401 : Access denied - credentials missing or invalied");
    return res.end("Access denied");
  }

  // Check if the credentials are valid by comparing them with the values stored in the database
  authenticate(req, res, next, (error, owner_user_id) => {
    if (error) {
      return res.status(error).send();
    }

    const checkQuery = "SELECT * FROM products WHERE id = ?";
    db.query(checkQuery, [productId], (error, result) => {
      if (error) {
        return res.status(500).send(error);
      }
      if (!result[0]) {
        logger.info("Status 404: Upload image faield - Product not found")
        return res.status(404).send({ message: "Product not found" });
      }
      if (result[0].owner_user_id !== owner_user_id) {
        logger.info("Status 403: Forbidden - Not authorized to add image to this product");
        return res.status(403).send({ message: "Forbidden, Not authorized to add image to this product" });
      }

      // Upload the file to S3 bucket
      const s3_params = {
        Bucket:'my-image-bucket-shardul-web',
        Key: `${productId}/${uuidv4()}`,
        Body: file_data,
        ContentType: file_type,
        ACL: 'public-read'
      };

      s3.upload(s3_params, (err, data) => {
        if (err) {
          console.error(err);
          logger.info("Status 400 : Failed to upload to s3");
          res.status(400).json({ error: 'Failed to upload image to S3' });
        } else {
          const s3_bucket_path = data.Location;

          // Store the image metadata in MySQL database
          const query = `
            INSERT INTO images (product_id, file_name, date_created, s3_bucket_path)
            VALUES (?, ?, NOW(), ?)
          `;
          const values = [productId, file_name, s3_bucket_path];

          db.query(query, values, (error, results) => {
            if (error) {
              console.error(error);
              logger.info("Status 400 : Failed to store image metadata in the database");
              res.status(400).json({ error: 'Failed to store image metadata in database' });
            } else {
              const image_id = results.insertId;
              const response_data = { image_id, productId, file_name, date_created: new Date().toISOString(), s3_bucket_path };
              logger.info("Status 201 : Image uploaded successfully");
              res.status(201).json(response_data);
            }
          });
        }
      });
    });
  });
};


export const getImagesByProductId = (req, res, next) => {
  logAPICall('Get_Image_By_Product_ID_API');
  logger.info("Get image by product ID API called");
  const productId = req.params.productId;
  const credentials = auth(req);

  // If the credentials are missing or invalid, return an error
  if (!credentials || !credentials.name || !credentials.pass) {
    res.statusCode = 401;
    res.setHeader("WWW-Authenticate", "Basic realm='example'");
    return res.end("Access denied");
  }

  // Check if the credentials are valid by comparing them with the values stored in the database
  authenticate(req, res, next, (error, owner_user_id) => {
    if (error) {
      return res.status(error).send();
    }

    const checkQuery = "SELECT * FROM products WHERE id = ? AND owner_user_id = ?";
    db.query(checkQuery, [productId, owner_user_id], (error, result) => {
      if (error) {
        return res.status(500).send(error);
      }
      if (!result[0]) {
        return res.status(403).send({ message: "Forbidden, Not authorized to access images of this product" });
      }

      const query = `
        SELECT *
        FROM images
        WHERE product_id = ?
      `;
      const values = [productId];

      db.query(query, values, (error, results) => {
        if (error) {
          console.error(error);
          res.status(500).json({ error: 'Failed to get images from database' });
        } else {
          res.status(200).json(results);
        }
      });
    });
  });
};


// get individual product details

export const getImageById = (req, res, next) => {
  logAPICall('Get_Image_By_ID_API');
  logger.info("Get image by product ID API called");
  const credentials = auth(req);

  // If the credentials are missing or invalid, return an error
  if (!credentials || !credentials.name || !credentials.pass) {
    res.statusCode = 401;
    res.setHeader("WWW-Authenticate", "Basic realm='example'");
    return res.end("Access denied");
  }

  // Check if the credentials are valid by comparing them with the values stored in the database
  authenticate(req, res, next, (error, owner_user_id) => {
    if (error) {
      return res.status(error).send();
    }

    const imageId = req.params.image_id;
    const productId = req.params.productId;
    const checkQuery = "SELECT * FROM products WHERE id = ? AND owner_user_id = ?";
    db.query(checkQuery, [productId, owner_user_id], (error, result) => {
      if (error) {
        return res.status(500).send(error);
      }
      if (!result[0]) {
        return res.status(403).send({ message: "Forbidden, Not authorized to access images of this product" });
      }

      const query = `
        SELECT *
        FROM images
        WHERE image_id = ? AND product_id = ?
      `;
      const values = [imageId, productId];

      db.query(query, values, (error, results) => {
        if (error) {
          console.error(error);
          res.status(500).json({ error: 'Failed to get image from database' });
        } else {
          if (!results[0]) {
            return res.status(404).send({ message: "Image not found for this product" });
          } else {
            res.status(200).json(results[0]);
          }
        }
      });
    });
  });
};

export const deleteImage = (req, res, next) => {
  logAPICall('Delete_Image_API');
  logger.info("Delete image API called");
  const imageId = req.params.imageId;
  const credentials = auth(req);

  // If the credentials are missing or invalid, return an error
  if (!credentials || !credentials.name || !credentials.pass) {
    res.statusCode = 401;
    res.setHeader("WWW-Authenticate", "Basic realm='example'");
    logger.info("Status 401: Access denied - credentials missing or invalid");
    return res.end("Access denied");
  }

  // Check if the credentials are valid by comparing them with the values stored in the database
  authenticate(req, res, next, (error, owner_user_id) => {
    if (error) {
      return res.status(error).send();
    }

    const checkQuery = "SELECT * FROM images WHERE image_id = ?";
    db.query(checkQuery, [imageId], (error, result) => {
      if (error) {
        return res.status(500).send(error);
      }
      if (!result[0]) {
        logger.info("Status 404: Delete image failed - Image not found");
        return res.status(404).send({ message: "Image not found" });
      }
      const productId = result[0].product_id;

      const checkOwnershipQuery = "SELECT * FROM products WHERE id = ?";
      db.query(checkOwnershipQuery, [productId], (error, result) => {
        if (error) {
          return res.status(500).send(error);
        }
        if (!result[0]) {
          logger.info("Status 404: Delete image failed - Product not found");
          return res.status(404).send({ message: "Product not found" });
        }
        if (result[0].owner_user_id !== owner_user_id) {
          logger.info("Status 403: Forbidden - Not authorized to delete image from this product");
          return res.status(403).send({ message: "Forbidden, Not authorized to delete image from this product" });
        }

        // Delete the file from S3 bucket
        const s3_params = {
          Bucket: 'my-image-bucket-shardul-web',
          Key: result[0].s3_bucket_path
        };

        s3.deleteObject(s3_params, (err, data) => {
          if (err) {
            console.error(err);
            logger.info("Status 400 : Failed to delete image from s3");
            res.status(400).json({ error: 'Failed to delete image from S3' });
          } else {
            // Delete the image metadata from MySQL database
            const query = "DELETE FROM images WHERE image_id = ?";
            const values = [imageId];

            db.query(query, values, (error, results) => {
              if (error) {
                console.error(error);
                logger.info("Status 400 : Failed to delete image metadata from database");
                res.status(400).json({ error: 'Failed to delete image metadata from database' });
              } else {
                logger.info("Status 200 : Image deleted successfully");
                res.status(200).send();
              }
            });
          }
        });
      });
    });
  });
};
