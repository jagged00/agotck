Includes = {
	"cw/pdxmesh_buffers.fxh"
	"gh_portrait_decals_shared.fxh"
	"gh_markers.fxh"
}

# Copy of camera.fhx constants, but re-named so they can be accessed without macros screwing things up
ConstantBuffer( PdxCamera )
{
	float4x4	View_Projection_Matrix;
	float4x4	Inv_View_Projection_Matrix;
	float4x4	View_Matrix;
	float4x4	Inv_View_Matrix;
	float4x4	Projection_Matrix;
	float4x4	Inv_Projection_Matrix;

	float4x4 	Shadow_Map_Texture_Matrix;
	
	float3		Camera_Position;
	float		Z_Near;
	float3		Camera_Look_At_Dir;
	float		Z_Far;
	float3		Camera_Up_Dir;
	float 		Camera_FoV;
	float3		Camera_Right_Dir;
	float 		_Upscale_Lod_Bias;
	float 		_Upscale_Lod_Bias_Native;
	float 		_Upscale_Lod_Bias_Multiplier;
	float 		_Upscale_Lod_Bias_Multiplier_Native;
	float 		_Upscale_Lod_Bias_Enabled;
}


Code
[[	
	// Macros that replace references to vanilla camera constants with functions for modifying them
	#ifdef PORTRAIT_WIDGET
		#define CameraPosition 				Camera_Position_Mod()
		#define ViewMatrix 					View_Matrix_Mod()
		#define	InvViewMatrix 				Inv_View_Matrix_Mod()
		#define	ViewProjectionMatrix 		View_Projection_Matrix_Mod()
		#define	InvViewProjectionMatrix 	Inv_View_Projection_Matrix_Mod()
		#define ShadowMapTextureMatrix 		Shadow_Map_Texture_Matrix
	#endif

	static const float  MAX_ZOOM_DISTANCE	= 	7500.0f; // The maximum distance you'd like to move the camera back for max zoom.
	static const float  MAX_RAISE_HEIGHT	= 	1500.0f; // The maximum distance you'd like to move the camera back for max zoom.

	// Move camera back
	float3 Camera_Position_Mod()
	{
		float2 ZoomHeight = GetCameraZoomFromMarkerDecals();
		float ZoomFactor = lerp(0.0f, MAX_ZOOM_DISTANCE, ZoomHeight.x);
		float AddCameraHeight = lerp(0.0f, MAX_RAISE_HEIGHT, ZoomHeight.y);
		// Compute the new camera position
		float3 NewCameraPos = Camera_Position - Camera_Look_At_Dir * ZoomFactor;

		//Raise Camera
		NewCameraPos.y += AddCameraHeight;

		return NewCameraPos;
	}

	// Generate new View Matrix using new camera
	float4x4 View_Matrix_Mod()
	{
		float3 zaxis = Camera_Look_At_Dir;    // The "forward" vector.
		float3 xaxis = Camera_Right_Dir;     // The "right" vector.
		float3 yaxis = Camera_Up_Dir;        // The "up" vector.
		
		float4 newViewMatrix0 = float4(xaxis.x, yaxis.x, zaxis.x, 0);
		float4 newViewMatrix1 = float4(xaxis.y, yaxis.y, zaxis.y, 0);
		float4 newViewMatrix2 = float4(xaxis.z, yaxis.z, zaxis.z, 0);
		float4 newViewMatrix3 = float4(-dot(xaxis, CameraPosition), -dot(yaxis, CameraPosition), -dot(zaxis, CameraPosition), 1);

		return float4x4 (Create4x4( newViewMatrix0, newViewMatrix1, newViewMatrix2, newViewMatrix3 ));
	}

	float4x4 Inv_View_Matrix_Mod()
	{
		return float4x4 (transpose(ViewMatrix));
	}

	// Create new ViewProjectionMatrix using new ViewMatrix
	float4x4 View_Projection_Matrix_Mod()
	{
		return float4x4 (mul(Projection_Matrix, ViewMatrix));
	}

	float4x4 Inv_View_Projection_Matrix_Mod()
	{
		return float4x4 (transpose(ViewProjectionMatrix));
	}

	
	

]]
