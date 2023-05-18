import express from 'express';

import {createUser, getuser, login, update ,createProduct, getImageById, deleteProduct, getImagesByProductId ,updateProduct, updateProductPatch, returnProduct, uploadImage, deleteImage} from '../controller/users_c.js';

//all routes here start with "/v1"

const router = express.Router();
import multer from 'multer';
export const storage = multer.memoryStorage();
export const upload = multer({
    storage: storage,
    limits: { fileSize: 5 * 1024 * 1024 } // 5MB limit
  });

// user routes

router.get('/', getuser);
router.post('/user', createUser);
router.get('/login', login );
router.put('/update', update );

// product routes

router.post('/product', createProduct);
router.delete("/product/:productId", deleteProduct);
router.put("/product/:productId", updateProduct);
router.patch("/product/:productId", updateProductPatch);
router.get("/product/:productId", returnProduct );

//image routes
router.get("/product/:productId/image", getImagesByProductId);
router.get("/product/:productId/image/:image_id", getImageById);
router.delete("/product/:productId/image/:imageId", deleteImage);
router.post('/product/:productId/image', upload.single('image'), uploadImage);

export default router;