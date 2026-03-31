includes = {
	"jomini/texture_decals_base.fxh"
	"jomini/portrait_user_data.fxh"
	# MOD(godherja)
	"standardfuncsgfx.fxh"
	"gh_portrait_decals_shared.fxh"
	#"gh_portrait_effects.fxh"
	"gh_constants.fxh"
	"gh_utils.fxh"
	# END MOD
}

PixelShader =
{
	# MOD(godherja)
	# The following definitions were moved into gh_portrait_decal_data.fxh,
	# since Godherja needs them to be shared between pixel and vertex shaders across several files.
	# That file needs to be kept in sync with vanilla as new patches come out.

	#TextureSampler DecalDiffuseArray
	#{
	#	Ref = JominiPortraitDecalDiffuseArray
	#	MagFilter = "Linear"
	#	MinFilter = "Linear"
	#	MipFilter = "Linear"
	#	SampleModeU = "Clamp"
	#	SampleModeV = "Clamp"
	#	type = "2darray"
	#}

	#TextureSampler DecalNormalArray
	#{
	#	Ref = JominiPortraitDecalNormalArray
	#	MagFilter = "Linear"
	#	MinFilter = "Linear"
	#	MipFilter = "Linear"
	#	SampleModeU = "Clamp"
	#	SampleModeV = "Clamp"
	#	type = "2darray"
	#}

	#TextureSampler DecalPropertiesArray
	#{
	#	Ref = JominiPortraitDecalPropertiesArray
	#	MagFilter = "Linear"
	#	MinFilter = "Linear"
	#	MipFilter = "Linear"
	#	SampleModeU = "Clamp"
	#	SampleModeV = "Clamp"
	#	type = "2darray"
	#}

	#BufferTexture DecalDataBuffer
	#{
	#	Ref = JominiPortraitDecalData
	#	type = uint
	#}
	# END MOD

	Code
	[[		
		//MOD
		#define BODYPART_EYES         1
		#define BODYPART_DRAGON       2

		//Following make MIP decoding code easier to read
		static const float3 RED 	= 	float3(1.0f,0.0f,0.0f);
		static const float3 GREEN 	= 	float3(0.0f,1.0f,0.0f);
		static const float3 BLUE 	= 	float3(0.0f,0.0f,1.0f);
		static const float3 CYAN 	=	float3(0.0f,1.0f,1.0f);
		static const float3 MAGENTA =	float3(1.0f,0.0f,1.0f);
		static const float3 YELLOW 	=	float3(1.0f,1.0f,0.0f);

		#define DIFFUSE_DECAL uint(0)	
		#define NORMAL_DECAL uint(1)	
		#define PROPERTIES_DECAL uint(2)

		#define SKIN uint(0)	
		#define EYE uint(1)	
		#define HAIR uint(2)	

		//Custom DX/OPENGL Defines

		#ifndef PDX_OPENGL
		#define GH_PdxTex2DArrayLoad(samp,uvi,lod) (samp)._Texture.Load( int4((uvi), (lod)) )
		#define EK2_PdxTex2DArraySize(samp,size) (samp)._Texture.GetDimensions( (size).x, (size).y, (size).z )


		#else
		#define GH_PdxTex2DArrayLoad texelFetch
		#define EK2_PdxTex2DArraySize(samp,size) size = textureSize((samp), 0)
		#endif
		//EK2

		// MOD(godherja)

		// This definition was commented out here and extracted into gh_portrait_decal_data.fxh
		// because custom Godherja code from gh_portrait_effects.fxh also depends on it.
		// Any vanilla patches' changes to this definition need to be merged into gh_portrait_decal_data.fxh as well.

		// struct DecalData
		// {
		// 	uint _DiffuseIndex;
		// 	uint _NormalIndex;
		// 	uint _PropertiesIndex;
		// 	uint _BodyPartIndex;

		// 	uint _DiffuseBlendMode;
		// 	uint _NormalBlendMode;
		// 	uint _PropertiesBlendMode;
		// 	float _Weight;

		// 	uint2 _AtlasPos;
		// 	float2 _UVOffset;

		// 	uint _AtlasSize;
		// };

		// END MOD

		DecalData GetDecalData( int Index )
		{
			// Data for each decal is stored in multiple texels as specified by DecalData

			DecalData Data;

			Data._DiffuseIndex = PdxReadBuffer( DecalDataBuffer, Index );
			Data._NormalIndex = PdxReadBuffer( DecalDataBuffer, Index + 1 );
			Data._PropertiesIndex = PdxReadBuffer( DecalDataBuffer, Index + 2 );
			Data._BodyPartIndex = PdxReadBuffer( DecalDataBuffer, Index + 3 );

			Data._DiffuseBlendMode = PdxReadBuffer( DecalDataBuffer, Index + 4 );
			Data._NormalBlendMode = PdxReadBuffer( DecalDataBuffer, Index + 5 );
			if ( Data._NormalBlendMode == BLEND_MODE_OVERLAY )
			{
				Data._NormalBlendMode = BLEND_MODE_OVERLAY_NORMAL;
			}
			Data._PropertiesBlendMode = PdxReadBuffer( DecalDataBuffer, Index + 6 );
			Data._Weight = Unpack16BitUnorm( PdxReadBuffer( DecalDataBuffer, Index + 7 ) );

			Data._AtlasPos = uint2( PdxReadBuffer( DecalDataBuffer, Index + 8 ), PdxReadBuffer( DecalDataBuffer, Index + 9 ) );
			Data._UVOffset = float2( Unpack16BitUnorm( PdxReadBuffer( DecalDataBuffer, Index + 10 ) ), Unpack16BitUnorm( PdxReadBuffer( DecalDataBuffer, Index + 11 ) ) );
			Data._UVTiling = uint2( PdxReadBuffer( DecalDataBuffer, Index + 12 ), PdxReadBuffer( DecalDataBuffer, Index + 13 ) );

			Data._AtlasSize = PdxReadBuffer( DecalDataBuffer, Index + 14 );

			return Data;
		}

		//EK2 


		// This function tells us which MIP level we need to sample, to retrieve the "absolute" MIP6 containing our encoded pixels.
		// It's needed because using lower texture settings in the game change which MIP level is beings sampled.
		// I.e. Sampling MIP6 on "Ultra" settings would sample MIP6 texture correctly
		// But Sampling MIP6 on "High" settings would actually sample MIP7, because the game is using the texture MIP1 as MIP0 in the shader for lower graphical settings.
		// Essentially this figures out which MIP level we need to sample to find the one with 16x16px dimensions.

		uint GetMIP6Level()
		{
			/////////////////////////// FIND CURRENT MIP LEVEL ///////////////////////////
			float3 TextureSize;
			EK2_PdxTex2DArraySize(DecalDiffuseArray, TextureSize);

			//Get log base 2 for current texture size (1024px - 10, 512px - 9, etc.)
			//Take that away from 10 to find the current MIP level.
			//Take that away from 6 to find which MIP We need to sample in the texture buffer to retrieve the "absolute" MIP6 containing our encoded pixels
			uint MIP = uint(6.0f-(10.0f - log2(TextureSize.x)));
			return MIP;
		}

		bool AlmostEquals(float3 Sample, float3 Mask)
		{
			//Allowing for a little bit of compression error.
			float MaskTolerance = 0.03f;

			if (
			Sample.r >= (Mask.r-MaskTolerance) &&
			Sample.r <= (Mask.r+MaskTolerance) &&
			Sample.g >= (Mask.g-MaskTolerance) &&
			Sample.g <= (Mask.g+MaskTolerance) &&
			Sample.b >= (Mask.b-MaskTolerance) &&
			Sample.b <= (Mask.b+MaskTolerance)
			)
			{			
				return true;
			}
			else
			{
				return false;
			}	


		}

		//Loops through all decals until it finds a decal matching the DecalMask colour in MIP6, then returns it's decal data.
 		//Used for getting weight of a decal to use for various types of blending effects outside of PS_Skin, like decaying clothing.

		DecalData GetDecalData(float3 DecalMask, uint DecalType, int To, bool IsDynamicTerrainLoaded = true)
		{
			float3 DecalMIP6_1_1_Sample;

			const int TEXEL_COUNT_PER_DECAL = 15;
			int ToDataTexel = To * TEXEL_COUNT_PER_DECAL;
			//int ToDataTexel = GH_AvoidTerrainMarkerDecalIndices(To, IsDynamicTerrainLoaded) * TEXEL_COUNT_PER_DECAL;
			//const uint MAX_VALUE = 65535;
			static const uint MAX_VALUE = GH_VANILLA_DATA_MAX_VALUE;
			uint CurrentLOD = GetMIP6Level();
			DecalData Data;

			for ( int i = 0; i <= ToDataTexel; i += TEXEL_COUNT_PER_DECAL )
			{
				Data = GetDecalData( i );

				if (DecalType == DIFFUSE_DECAL)
				{
					DecalMIP6_1_1_Sample = GH_PdxTex2DArrayLoad( DecalDiffuseArray, int3(1, 1, int(Data._DiffuseIndex)), int(CurrentLOD)).rgb;
				}

				else if (DecalType == NORMAL_DECAL)
				{
					DecalMIP6_1_1_Sample = GH_PdxTex2DArrayLoad( DecalNormalArray, int3(1, 1, int(Data._NormalIndex)), int(CurrentLOD)).rgb;
				}

				else
				{
					DecalMIP6_1_1_Sample = GH_PdxTex2DArrayLoad( DecalPropertiesArray, int3(1, 1, int(Data._PropertiesIndex)), int(CurrentLOD)).rgb;
				}



				if ( Data._DiffuseIndex < MAX_VALUE )
				{

					if (AlmostEquals(DecalMIP6_1_1_Sample,DecalMask))
						{			
							return Data;
						}
				}
				
			}
			return Data;
		
		}


		void RGBA_To_Atlas(inout float4 Decal, inout float Weight )
		{
			//Below If statements normalize the weight value to 0.0 - 1.0 then tells which channel to use as alpha at increments of 25%.
			if (Weight < 0.25f)
			{
			Weight = Weight * 4.0f;
			Decal.a = Decal.r;
			}

			else if (Weight >= 0.25f && Weight < 0.5f)
			{
			Weight = (Weight - 0.25f) * 4.0f;
			Decal.a = Decal.g;
			}

			else if (Weight >= 0.5f && Weight < 0.75f)
			{
			Weight = (Weight - 0.5f) * 4.0f;
			Decal.a = Decal.b;
			}

			else
			{
			Weight = (Weight - 0.75f) * 4.0f;
			}
		}
		//MOD

	//////////////////////////////////////////////////////////////////////////////
/////////////////////////			DECODE MIPS			///////////////////////////////
	//////////////////////////////////////////////////////////////////////////////

		void DecodeDiffuseMIPs( uint InstanceIndex, inout float4 Sample, float2 UV , inout DecalData Data, inout float4x4 WeightMatrix , int CustomBodyPart )
		{
			uint CurrentLOD = 	GetMIP6Level();
			
			//  MIP6 of a typical decal 1024x1024 texture is a 16x16px texture.
			//  We "smuggle" data into the mip map by colouring in 4x4 px blocks a certain colour and later sample specific coordinate for a specific colour.
			//  This gives us 16 unique "bits" to sample from. 4x4 cells are due to DDS compression algorithms which work in blocks of 4 pixels.
			//  We can then use that decals weight to apply various shader effect.
			//	Below is a visual representation/guide of a MIP6 texture along with sampling coordinates for reference."+" Symbolizes the actual pixel being sampled.
			//
			//       _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ 
			//  0,0 |  1,1  |  5,1  |  9,1  |  13,1 | 15,0
			//      |  +    |  +    |  +    |  +    |
			//      |       |       |       |       |
			//      |_ _ _ _|_ _ _ _|_ _ _ _|_ _ _ _|
			//      |  1,5  |  5,5  |  9,5  |  13,5 |
			//      |  +    |  +    |  +    |  +    |
			//      |       |       |       |       |
			//      |_ _ _ _|_ _ _ _|_ _ _ _|_ _ _ _|
			//      |  1,9  |  5,9  |  9,9  |  13,9 |
			//      |  +    |  +    |  +    |  +    |
			//      |       |       |       |       |
			//      |_ _ _ _|_ _ _ _|_ _ _ _|_ _ _ _|
			//      |  1,13 |  5,13 |  9,13 | 13,13 |
			//      |  +    |  +    |  +    |  +    |
			//      |       |       |       |       |
			// 0,15 |_ _ _ _|_ _ _ _|_ _ _ _|_ _ _ _| 15,15

			
			///////// 1,1 SAMPLE (TOP LEFT BLOCK)/////////
            /////////////// CONTROL DECALS ///////////////

			// These are normally not actually displayed on the mesh. Most of the time alpha is set to 0 on the decal texture if it is only a marker texture.
			// If we do want to use that decal weight for some skin decal like body hair colour selection or facepaint colour selection then we store the weight into the weight matrix below.
			// Sometimes we do want to use the texture data for something so we force the texture weight to 0.0 below so it does not get rendered.

			// float3 (1.0f,0.0f,0.0f) - CLOTHES DECAY CONTROL
			// float3 (0.0f,1.0f,0.0f) - SALT AND PEPPER HAIR CONTROL
			// float3 (0.0f,0.0f,1.0f) - FACEPAINT SELECTION DECAL
			// float3 (0.0f,1.0f,1.0f) - ATTACHMENT PATTERN PALETTE SELECTION (OBSOLETE)
			// float3 (1.0f,0.0f,1.0f) - FUR COLOUR TRANSITION - EK2 KHAJIIT/IMGA
			// float3 (0.5f,0.0f,0.0f) - BODY HAIR COLOUR SELECTION
			// float3 (1.0f,1.0f,0.0f) - SKELETON TRANSITION EFFECT - HEAD - EK2
			// float3 (0.0f,0.5f,0.0f) - SKELETON TRANSITION EFFECT - BODY - EK2
			// float3 (0.0f,0.0f,0.5f) - DRAGON COLOR PALETTE MARKER

			float3 DecalMIP6_1_1_Sample = GH_PdxTex2DArrayLoad( DecalDiffuseArray, int3(1, 1, int(InstanceIndex)), int(CurrentLOD)).rgb;

			// CLOTHES DECAY CONTROL
			if (AlmostEquals(DecalMIP6_1_1_Sample,RED))
			{			
				WeightMatrix[0][0] = 0.0f;
				return;
			}

			if (AlmostEquals(DecalMIP6_1_1_Sample,GREEN))
			{			
				WeightMatrix[0][0] = 0.0f;
				return;
			}

			// FACEPAINT SELECTION DECAL
			if (AlmostEquals(DecalMIP6_1_1_Sample,BLUE))
			{	
			WeightMatrix[0][0] = 0.0f;		
			WeightMatrix[0][1] = Data._Weight;
			return;
			}			

			//BODY HAIR COLOR SELECTION
			else if (AlmostEquals(DecalMIP6_1_1_Sample,float3 (0.5f,0.0f,0.0f)))
			{	
			WeightMatrix[0][0] = 0.0f;		
			WeightMatrix[0][2] = Data._Weight;
			return;
			}		
	
			//DRAGON COLOR MARKER
			else if (AlmostEquals(DecalMIP6_1_1_Sample, float3 (0.0f,0.0f,0.5f)))
			{	
			WeightMatrix[0][0] = 0.0f;		
			return;
			}	
	

			///////// 5,1 SAMPLE (2ND ROW, 1ST COLUMN CELL)/////////
            ////////////////// CUSTOM BODY PARTS //////////////////

			float3 DecalMIP6_5_1_Sample = GH_PdxTex2DArrayLoad( DecalDiffuseArray, int3(5, 1, int(InstanceIndex)), int(CurrentLOD)).rgb;

			//float3 (1.0f,0.0f,0.0f) - DRAGON BODY
			//float3 (0.0f,1.0f,0.0f) - EYE DECAL - EK2
			//float3 (0.0f,0.0f,1.0f) - DRAGON WINGS
			//float3 (1.0f,1.0f,0.0f) - DRAGON HORNS
			//float3 (0.0f,1.0f,1.0f) - DRAGON EYES

			//This sets custom body parts. At 0 decals are applied like normal.
			//If set at anything other than 0 it will override where the decal is supposed to show

			//If not using a custom body part, but decal is encoded to display only on custom body parts list above, hide the decal.
			if (CustomBodyPart == 0)
			{
				if (AlmostEquals(DecalMIP6_5_1_Sample,GREEN))
				{			
					WeightMatrix[0][0] = 0.0f;
					return;
				}

				//Ignore dragon decals
				else if (AlmostEquals(DecalMIP6_5_1_Sample,RED))
				{			
					WeightMatrix[0][0] = 0.0f;
					return;
				}

				else if (AlmostEquals(DecalMIP6_5_1_Sample,BLUE))
				{			
					WeightMatrix[0][0] = 0.0f;
					return;
				}

				else if (AlmostEquals(DecalMIP6_5_1_Sample,float3 (1.0f,1.0f,0.0f)))
				{			
					WeightMatrix[0][0] = 0.0f;
					return;
				}

				else if (AlmostEquals(DecalMIP6_5_1_Sample,float3 (0.0f,1.0f,1.0f)))
				{			
					WeightMatrix[0][0] = 0.0f;
					return;
				}
			}

			//If using custom body part, and the decal encoding matches the body part in the list, display the decal.
			else if (CustomBodyPart == BODYPART_EYES)
			{
				if (AlmostEquals(DecalMIP6_5_1_Sample,GREEN))
				{			
					WeightMatrix[0][0] = Data._Weight ;
				}

				// Else if using custom body part, but the decal encoding doesn't match, hide decals.
				else
				{
					WeightMatrix[0][0] = 0.0f;
					return;
				}
			}


/////////////////////////// CUSTOM UV MAPPING AND CHANNEL SPLITTING //////////////////////////////////			
			//Sample bottom left corner pixel of decal MIP5.
			//Used to tell the shader how to split the decal:
			//R - SPLIT INTO 4 DECALS THAT CHANGE EVERY 25% USING RGBA AS MASKS
			//G - BLANK
			//B - BLANK
			float3 DecalMIP6_9_1_Sample = GH_PdxTex2DArrayLoad( DecalDiffuseArray, int3(9, 1, int(InstanceIndex)), int(CurrentLOD)).rgb;

			// If bottom left corner pixel is RED - Split into 4 decals every 25% of weight slider masked by channel
			if ( AlmostEquals(DecalMIP6_9_1_Sample, RED))
			{
				RGBA_To_Atlas(Sample, WeightMatrix[0][0] );
			}


/////////////////////////// CUSTOM COLOUR OVERRIDES //////////////////////////////////	

			//Sample top right corner pixel of decal MIP5.
			//For overwriting color of decal 
			//R - OVERRIDE COLOUR BY SAMPLING A COLOUR PALETTE, CHANGES COLOUR WITH WEIGHT OF DECAL - SETS WEIGHT TO 100%
			//G - OVERRIDE COLOUR TO CURRENT SKIN COLOUR PALETTE
			//B - OVERRIDE COLOUR TO CURRENT HAIR COLOUR PALETTE
			//Y - OVERRIDE COLOUR TO CURRENT EYE COLOUR PALETTE
			//C - OVERRIDE COLOUR BY SAMPLING TOP LEFT CORNER OF MIP WHICH STORES A COLOUR PALETTE, CHANGES COLOUR WITH WEIGHT OF DECAL - KEEPS WEIGHT AS IS (ALLOWS ADJUSTING TRASPARENCY)
			//M - REPLACES DECAL COLOR WITH SAMPLED PALETTE AND SETS OPACITY TO 100%
			//float3 (0.5f,0.0f,0.0f) - BODY HAIR DECAL COLOUR CHANGE
			
			float3 DecalMIP6_13_1_Sample = GH_PdxTex2DArrayLoad( DecalDiffuseArray, int3(13, 1, int(InstanceIndex)), int(CurrentLOD)).rgb;

			// If top right corner pixel is RED - REPLACES DECAL COLOR WITH SAMPLED PALETTE FROM TOP LEFT OF THE DECAL AND SETS OPACITY TO 100%  - USE ANOTHER DECAL TO CONTROL THE STRENGTH
			if ( AlmostEquals(DecalMIP6_13_1_Sample,RED))
			{
				//Sample top left corner pixels of the image MIP5 as makeshift color palette for the facepaint, then apply that color and the correct alpha and set Weight (transperancy to 100%)
				float3 EKDecalPaletteColor = GH_PdxTex2DArrayLoad( DecalDiffuseArray, int3(int(WeightMatrix[0][1]*16), 13, int(InstanceIndex)), int(CurrentLOD)).rgb;
				Sample.rgb = EKDecalPaletteColor;
				WeightMatrix[0][0] = 1.0f;
			}

			// If top right corner pixel is GREEN - REPLACES DECAL COLOR WITH SKIN COLOR,
			else if ( AlmostEquals(DecalMIP6_13_1_Sample,GREEN))
			{
				Sample.rgb = vPaletteColorSkin.rgb;
			}

			// If top right corner pixel is BLUE - REPLACES DECAL COLOR WITH HAIR COLOR
			else if ( AlmostEquals(DecalMIP6_13_1_Sample,BLUE))
			{
				Sample.rgb = vPaletteColorHair.rgb;
			}

			// If top right corner pixel is YELLOW - REPLACES DECAL COLOR WITH EYE COLOR
			else if ( AlmostEquals(DecalMIP6_13_1_Sample,YELLOW))
			{
				Sample.rgb = vPaletteColorEyes.rgb;
			}

			// If top right corner pixel is CYAN - REPLACES DECAL COLOR WITH SAMPLED COLOR FROM BOTTOM LEFT OF THE MIP6 AND LEAVE OPACITY NORMALISED PER DECAL
			else if ( AlmostEquals(DecalMIP6_13_1_Sample,CYAN))
			{
				//Sample bottom left corner pixels of the image as color for the decal, then apply that color
				float3 EKDecalPaletteColor = GH_PdxTex2DArrayLoad( DecalDiffuseArray, int3(1, 13, int(InstanceIndex)), int(CurrentLOD)).rgb;
				Sample.rgb = EKDecalPaletteColor;
			}

			// If top right corner pixel is MAGENTA - REPLACES DECAL COLOR WITH SAMPLED PALETTE FROM TOP LEFT OF THE DECAL AND SETS OPACITY TO 100%
			else if ( AlmostEquals(DecalMIP6_13_1_Sample,MAGENTA))
			{

				//Sample top left corner pixels of the image MIP6 as makeshift color palette for the facepaint, then apply that color and the correct alpha and set Weight (transperancy to 100%)
				float3 EKDecalPaletteColor = GH_PdxTex2DArrayLoad( DecalDiffuseArray, int3(int(WeightMatrix[0][1]*16), 13, int(InstanceIndex)), int(CurrentLOD)).rgb;
				Sample.rgb = EKDecalPaletteColor;
				WeightMatrix[0][0] = 1.0f;
			}

			// Interpolates between a black and hair colour, for body/facial hair decals.
			else if ( AlmostEquals(DecalMIP6_13_1_Sample,float3 (0.5f,0.0f,0.0f)))
			{
				Sample.rgb = lerp (lerp(vPaletteColorHair.rgb, vPaletteColorHair.rgb*vPaletteColorSkin.rgb, 0.8f), float3(0.0f,0.0f,0.0f), WeightMatrix[0][2]);
			}


/////////////////////////// CUSTOM BLEND MODES //////////////////////////////////	

			//Sample bottom right corner pixel of decal MIP5.
			//For assigning custom blendmodes
			//R - SCREEN 
			//G - ADDITIVE.
			float3 DecalMIP6_1_5_Sample = GH_PdxTex2DArrayLoad( DecalDiffuseArray, int3(1, 5, int(InstanceIndex)), int(CurrentLOD)).rgb;

			// If bottom right corner pixel is RED - CHANGE BLEND MODE TO SCREEN - EYE GLOW DECAL
			if ( AlmostEquals(DecalMIP6_1_5_Sample, RED))
			{
				Data._DiffuseBlendMode = BLEND_MODE_SCREEN;
			}

			// If bottom right corner pixel is GREEN - CHANGE BLEND MODE TO ADDITIVE - EYE WHITE GLOW DECAL
			else if ( AlmostEquals(DecalMIP6_1_5_Sample, GREEN))
			{
				Data._DiffuseBlendMode = BLEND_MODE_ADDITIVE;
			}

			// If bottom right corner pixel is BLUE - CHANGE BLEND MODE TO MAX VALUE - KHAJIIT FUR
			else if ( AlmostEquals(DecalMIP6_1_5_Sample, BLUE))
			{
				Data._DiffuseBlendMode = BLEND_MODE_MAX_VALUE;
			}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


			WeightMatrix[0][0] *= Sample.a;
		}



		void DecodePropertiesMIPs( uint InstanceIndex , inout DecalData Data, inout float Weight, int CustomBodyPart )
		{

			uint CurrentLOD = GetMIP6Level();


/////////////////////////// MIP SAMPLING //////////////////////////////////


			//Sample top right corner pixel of decal MIP6. - WIP
			//R - DO NOT DRAW THE DECAL - USED FOR DECALS THAT CONTROL EFFECTS LIKE SALT N' PEPPER HAIR, AND CLOTHES DECAY
			//G - EYE DECAL - SO DECAL IS ONLY DRAWN ON EYES - CustomBodyPart = 1
			//REST OF CHANNELS WILL BE USED TO ASSIGN DECALS TO OTHER TYPES OF ATTACHMENTS IF NEEDED.

			float3 DecalMIP6_5_1_Sample = GH_PdxTex2DArrayLoad( DecalPropertiesArray, int3(5, 1, int(InstanceIndex)), int(CurrentLOD)).rgb;


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////			


 			if (AlmostEquals(DecalMIP6_5_1_Sample, RED))
			{			
				Weight = 0.0f;
				return;
			}

			//If MIP6-TR is green, and bodypartindex is set to eyes apply decal.
			if (CustomBodyPart == 0)
			{
				if (AlmostEquals(DecalMIP6_5_1_Sample,GREEN))
				{			
					Weight = 0.0f;
					return;
				}
			}

			//If using custom body part, and the decal encoding matches the body part in the list, display the decal.
			else if (CustomBodyPart == 2)
			{
				if (AlmostEquals(DecalMIP6_5_1_Sample,GREEN))
				{			
					Weight = Data._Weight;
				}

				// Else if using custom body part, but the decal encoding doesn't match, hide decals.
				else
				{
					Weight = 0.0f;
			 		return;
				}
			}

		}

		void AddDecals( inout float4 Diffuse, inout float3 Normals, inout float4 Properties, float2 UV, uint InstanceIndex, int From, int To /* EK2 - CUSTOM BODY PART */ , int CustomBodyPart, bool IsDynamicTerrainLoaded = true )
		{
			// Body part index is scripted on the mesh asset and should match ECharacterPortraitPart
			uint BodyPartIndex = GetBodyPartIndex( InstanceIndex );

			// MOD(godherja)
			const int TEXEL_COUNT_PER_DECAL = 15; // Extracted to GH_VANILLA_TEXEL_COUNT_PER_DECAL

			int FromDataTexel = From * GH_VANILLA_TEXEL_COUNT_PER_DECAL;
			int ToDataTexel = To * GH_VANILLA_TEXEL_COUNT_PER_DECAL;

			//int FromDataTexel = GH_AvoidTerrainMarkerDecalIndices(From, IsDynamicTerrainLoaded) * GH_VANILLA_TEXEL_COUNT_PER_DECAL;
			//int ToDataTexel   = GH_AvoidTerrainMarkerDecalIndices(To, IsDynamicTerrainLoaded)   * GH_VANILLA_TEXEL_COUNT_PER_DECAL;

			static const uint MAX_VALUE = GH_VANILLA_DATA_MAX_VALUE;
			// END MOD

			//EK2
			//Create a matrix for decal weights. Add more as needed (up to 16 in 4x4)
			//This is to allow using multiple genes to control a single effect.
			//For example x controls which facepaint design is used, and y will select a colour.

			//WeightMatrix[0][0] = Decal opacity
			//WeightMatrix[0][1] = Facepaint Selection
			//WeightMatrix[0][2] = Body Hair Colour
			//WeightMatrix[0][3] = UNUSED

			float4x4 WeightMatrix = Create4x4(
				float4 (0.0f, 0.0f, 0.0f, 0.0f),
				float4 (0.0f, 0.0f, 0.0f, 0.0f),
				float4 (0.0f, 0.0f, 0.0f, 0.0f),
				float4 (0.0f, 0.0f, 0.0f, 0.0f));
			//EK2

			// Sorted after priority
			// MOD(godherja)
			GH_LOOP
			// END MOD
			for ( int i = FromDataTexel; i <= ToDataTexel; i += GH_VANILLA_TEXEL_COUNT_PER_DECAL )
			{
				DecalData Data = GetDecalData( i );

				// Max index => unused
				if ( Data._BodyPartIndex == BodyPartIndex || CustomBodyPart != 0)
				{
					// Assumes that the cropped area size corresponds to the atlas factor
					float AtlasFactor = 1.0f / Data._AtlasSize;
					if ( ( ( UV.x >= Data._UVOffset.x ) && ( UV.x < ( Data._UVOffset.x + AtlasFactor ) ) ) &&
						 ( ( UV.y >= Data._UVOffset.y ) && ( UV.y < ( Data._UVOffset.y + AtlasFactor ) ) ) )
					{
						float2 DecalUV;
						float TilingMaskSample = 1;
						//UVTiling is incompatible with Decal Atlases, so we only use one of them. 
						//If a tiling value is provided, the tiling feature will be used.
						if ( Data._UVTiling.x == 1 && Data._UVTiling.y == 1 )
						{
							DecalUV = ( UV - Data._UVOffset ) + ( Data._AtlasPos * AtlasFactor );
						} 
						else
						{
							DecalUV = UV * Data._UVTiling;
							float2 TilingMaskUV = ( UV - Data._UVOffset ) + ( Data._AtlasPos * AtlasFactor );
							TilingMaskSample = PdxTex2D( DecalPropertiesArray, float3( TilingMaskUV, Data._PropertiesIndex ) ).r;
						}


					//EK2
					WeightMatrix[0][0] = Data._Weight;
					//EK2
					
						if ( Data._DiffuseIndex < MAX_VALUE )
						{
							// MOD(agot)
							// TODO: Verify that multiplying by TilingMaskSample (added in v1.12) is warranted here.
							WeightMatrix[0][0] *= TilingMaskSample;
							// END MOD

							//EK2
							//Sample LOD0 for eyes to avoid fading problems. TODO: Encode Mips to lower level to avoid this hack.
							#ifdef EYE_DECAL
							float4 DiffuseSample = PdxTex2DLod0( DecalDiffuseArray, float3( DecalUV, Data._DiffuseIndex ) );
							#else

							float4 DiffuseSample = PdxTex2D( DecalDiffuseArray, float3( DecalUV, Data._DiffuseIndex ) );
							#endif
							

							DecodeDiffuseMIPs( Data._DiffuseIndex, DiffuseSample, DecalUV , Data, WeightMatrix, CustomBodyPart  );	

							Diffuse = BlendDecal( Data._DiffuseBlendMode, Diffuse, DiffuseSample, WeightMatrix[0][0] );
							//END EK2
						}

						if ( Data._NormalIndex < MAX_VALUE )
						{
							

							float3 NormalSample = UnpackDecalNormal( PdxTex2D( DecalNormalArray, float3( DecalUV, Data._NormalIndex ) ), WeightMatrix[0][0] );

							Normals = BlendDecal( Data._NormalBlendMode, float4( Normals, 0.0f ), float4( NormalSample, 0.0f ), WeightMatrix[0][0] ).xyz;
						}

						if ( Data._PropertiesIndex < MAX_VALUE )
						{
							//EK2
							//Sample LOD0 for eyes to avoid fading problems. TODO: Encode Mips to lower level to avoid this hack.
							#ifdef EYE_DECAL
							float4 PropertiesSample = PdxTex2DLod0( DecalPropertiesArray, float3( DecalUV, Data._PropertiesIndex ) );
							#else

							float4 PropertiesSample = PdxTex2D( DecalPropertiesArray, float3( DecalUV, Data._PropertiesIndex ) );
							#endif

							


							//EK2

							DecodePropertiesMIPs( Data._PropertiesIndex , Data, WeightMatrix[0][0], CustomBodyPart );	

							//END EK2
							Properties = BlendDecal( Data._PropertiesBlendMode, Properties, PropertiesSample, WeightMatrix[0][0] );
						}
					}
				}
			}

			Normals = normalize( Normals );
		}

		#ifdef DRAGON_BODYPART_MARKER
		void ApplyDragonDamageDecal(inout float4 Texture, uint DecalType, float Weight, float3 RandomSeed, bool Accumulative, float2 UV, int TextureIndex, uint BlendMode)
		{
			float TileScale = 0.25f;
			const uint MaxNumIterations = 20u; // Total number of possible decals
			const float AtlasTileSize = 1.0f / 3.0f;

			uint numDecalsPerIncrement = 2u; // Number of decals to add per 10% weight increment
			uint currentIncrement = (uint)(floor(Weight * 10.0f)); // Number of 10% increments
			uint numDecalsToShow = currentIncrement * numDecalsPerIncrement; // Total decals to show

			// Ensure we don't exceed MaxNumIterations
			numDecalsToShow = min(numDecalsToShow, MaxNumIterations);

			// Loop over a fixed number of iterations
			[unroll]
			for (uint i = 0u; i < MaxNumIterations; ++i)
			{
				bool shouldExecute = false;

				if (Accumulative)
				{
					// Accumulative mode: show all decals up to numDecalsToShow
					shouldExecute = (i < numDecalsToShow);
				}
				else
				{
					// Non-accumulative mode: show decals for the current increment only
					if (currentIncrement == 0u)
					{
						shouldExecute = false; // No decals to show if weight is less than 10%
					}
					else
					{
						uint startIndex = (currentIncrement - 1u) * numDecalsPerIncrement;
						uint endIndex = currentIncrement * numDecalsPerIncrement - 1u;
						shouldExecute = (i >= startIndex && i <= endIndex);
					}
				}

				if (shouldExecute)
				{
					uint tileIndex = uint(CalcRandom(RandomSeed.x + float(i) * 23.456f) * 9.0f);

					float2 baseTileUVOffset = float2(
						(tileIndex % 3u) * AtlasTileSize,
						(tileIndex / 3u) * AtlasTileSize
					);

					float decalHalfSize = TileScale * 0.5f;
					float2 randomValue = float2(
						CalcRandom(RandomSeed.x + float(i) * 12.345f),
						CalcRandom(RandomSeed.y + float(i) * 67.890f)
					);

					// Adjust random center position to ensure decals are within UV space
					float2 centerUV = randomValue * (1.0f - 2.0f * decalHalfSize) + decalHalfSize;

					float2 decalMin = centerUV - decalHalfSize;
					float2 decalMax = centerUV + decalHalfSize;

					if (UV.x >= decalMin.x && UV.x <= decalMax.x &&
						UV.y >= decalMin.y && UV.y <= decalMax.y)
					{
						float2 decalUV = (UV - decalMin) / (2.0f * decalHalfSize);

						// Adjust decalUV to stay within [0.05, 0.95] to avoid edge bleeding
						decalUV = decalUV * 0.9f + 0.05f;

						// Map decalUV directly to the current tile in the atlas
						float2 newUV = decalUV * AtlasTileSize + baseTileUVOffset;
						float4 DecalSample;

						if (DecalType == DIFFUSE_DECAL)
						{
							DecalSample = PdxTex2D(DecalDiffuseArray, float3(newUV, TextureIndex));
							Texture.rgb = lerp(Texture.rgb, DecalSample.rgb, DecalSample.a);
						}
						else if (DecalType == NORMAL_DECAL)
						{
							DecalSample = PdxTex2D(DecalNormalArray, float3(newUV, TextureIndex));
							float3 NormalSample = UnpackDecalNormal(DecalSample, 1.0f);
							Texture.rgb = lerp(Texture.rgb, NormalSample, DecalSample.b);
						}
						else
						{
							DecalSample = PdxTex2D(DecalPropertiesArray, float3(newUV, TextureIndex));
							// Handle other decal types as needed
						}
					}
				}
			}
		}
		
		void AddDragonDecals( inout float4 Diffuse, inout float3 Normals, inout float4 Properties, inout float4 ColorMask, float2 UV0, float2 UV1, uint InstanceIndex )
		{
			uint CurrentLOD = GetMIP6Level();
			DecalData Data;

			const int TEXEL_COUNT_PER_DECAL = 15; // Extracted to GH_VANILLA_TEXEL_COUNT_PER_DECAL

			int PreSkinColorDecalDataTexel = PreSkinColorDecalCount * GH_VANILLA_TEXEL_COUNT_PER_DECAL;
			int TotalDecalDataTexel = DecalCount * GH_VANILLA_TEXEL_COUNT_PER_DECAL;

			static const uint MAX_VALUE = GH_VANILLA_DATA_MAX_VALUE;

			// Variables to store intermediate weights
			float DragonPrimaryColorX = 0.0f;
			float DragonPrimaryColorY = 0.0f;
			float DragonSecondaryColorX = 0.0f;
			float DragonSecondaryColorY = 0.0f;
			float DragonTertiaryColorX = 0.0f;
			float DragonTertiaryColorY = 0.0f;
			float DragonHornColorX = 0.0f;
			float DragonHornColorY = 0.0f;
			float DragonEyeColorX = 0.0f;
			float DragonEyeColorY = 0.0f;

			float3 DragonPrimaryColor = 	  float3(0.0f,0.0f,0.0f);
			float3 DragonSecondaryColor = 	  float3(0.0f,0.0f,0.0f);
			float3 DragonTertiaryColor = 	  float3(0.0f,0.0f,0.0f);
			float3 DragonHornColor =          float3(0.0f,0.0f,0.0f);
			float3 DragonEyeColor =           float3(0.0f,0.0f,0.0f);
			float3 ColorPalette =             float3(1.0f,1.0f,1.0f);

			// Counter to track the number of matches
			int matchCount = 0;
			float Weight = 0.0f;

			//PRE SKIN COLOUR DECALS
			GH_LOOP
			for ( int i = 0; i <= TotalDecalDataTexel; i += GH_VANILLA_TEXEL_COUNT_PER_DECAL )
			{
				Data = GetDecalData( i );
				Weight = Data._Weight;

				// Assumes that the cropped area size corresponds to the atlas factor
				float AtlasFactor = 1.0f / Data._AtlasSize;
				if ( ( ( UV0.x >= Data._UVOffset.x ) && ( UV0.x < ( Data._UVOffset.x + AtlasFactor ) ) ) &&
						( ( UV0.y >= Data._UVOffset.y ) && ( UV0.y < ( Data._UVOffset.y + AtlasFactor ) ) ) )
				{
					float2 DecalUV;
					float TilingMaskSample = 1;
					//UVTiling is incompatible with Decal Atlases, so we only use one of them. 
					//If a tiling value is provided, the tiling feature will be used.
					if ( Data._UVTiling.x == 1 && Data._UVTiling.y == 1 )
					{
						DecalUV = ( UV0 - Data._UVOffset ) + ( Data._AtlasPos * AtlasFactor );
					} 
					else
					{
						DecalUV = UV0 * Data._UVTiling;
						float2 TilingMaskUV = ( UV0 - Data._UVOffset ) + ( Data._AtlasPos * AtlasFactor );
						TilingMaskSample = PdxTex2D( DecalPropertiesArray, float3( TilingMaskUV, Data._PropertiesIndex ) ).r;
					}

					//Sample dragon colours
					if (AlmostEquals(GH_PdxTex2DArrayLoad(DecalDiffuseArray, int3(1, 1, int(Data._DiffuseIndex)), int(CurrentLOD)).rgb, float3(0.0f,0.0f,0.5f)))
					{
						matchCount++;
						switch (matchCount)
						{
							case 1:
								DragonPrimaryColorX = Data._Weight;
								break;
							case 2:
								DragonPrimaryColorY = Data._Weight;
								DragonPrimaryColor = PdxTex2D(DecalDiffuseArray, float3(DragonPrimaryColorX, DragonPrimaryColorY, Data._DiffuseIndex)).rgb;
								ColorPalette = lerp(ColorPalette,DragonPrimaryColor,ColorMask.r);
								break;
							case 3:
								DragonSecondaryColorX = Data._Weight;
								break;
							case 4:
								DragonSecondaryColorY = Data._Weight;
								DragonSecondaryColor = PdxTex2D(DecalDiffuseArray, float3(DragonSecondaryColorX, DragonSecondaryColorY, Data._DiffuseIndex)).rgb;
								ColorPalette = lerp(ColorPalette,DragonSecondaryColor,ColorMask.b);
								break;
							case 5:
								DragonTertiaryColorX = Data._Weight;
								break;
							case 6:
								DragonTertiaryColorY = Data._Weight;
								DragonTertiaryColor = PdxTex2D(DecalDiffuseArray, float3(DragonTertiaryColorX, DragonTertiaryColorY, Data._DiffuseIndex)).rgb;
								break;	
							case 7:
								DragonEyeColorX = Data._Weight;
								break;
							case 8:
								DragonEyeColorY = Data._Weight;
								DragonEyeColor = PdxTex2D(DecalDiffuseArray, float3(DragonEyeColorX, DragonEyeColorY, Data._DiffuseIndex)).rgb;
								ColorPalette = lerp(ColorPalette,DragonEyeColor,ColorMask.a);
								break;
							case 9:
								DragonHornColorX = Data._Weight;
								break;
							case 10:
								DragonHornColorY = Data._Weight;
								DragonHornColor = PdxTex2D(DecalDiffuseArray, float3(DragonHornColorX, DragonHornColorY, Data._DiffuseIndex)).rgb;
								ColorPalette = lerp(ColorPalette,DragonHornColor,ColorMask.g);
								break;
						}
					}	

					float3 RandomSeed = DragonPrimaryColor - DragonSecondaryColor + DragonEyeColor - DragonHornColor;

					//Diffuse Decal
					if (AlmostEquals(GH_PdxTex2DArrayLoad(DecalDiffuseArray, int3(5, 1, int(Data._DiffuseIndex)), int(CurrentLOD)).rgb, DRAGON_BODYPART_MARKER) )
					{
						//Dragon wound decal
						if (AlmostEquals(GH_PdxTex2DArrayLoad(DecalDiffuseArray, int3(9, 1, int(Data._DiffuseIndex)), int(CurrentLOD)).rgb, float3(1.0f,0.0f,0.0f)) )
						{
							ApplyDragonDamageDecal(Diffuse, DIFFUSE_DECAL, Weight, RandomSeed, 0, UV1, int(Data._DiffuseIndex),Data._DiffuseBlendMode);
						}
						//Dragon scar decal
						else if (AlmostEquals(GH_PdxTex2DArrayLoad(DecalDiffuseArray, int3(9, 1, int(Data._DiffuseIndex)), int(CurrentLOD)).rgb, float3(0.0f,1.0f,0.0f)) )
						{
							ApplyDragonDamageDecal(Diffuse, DIFFUSE_DECAL, Weight, RandomSeed, 1, UV1, int(Data._DiffuseIndex),Data._DiffuseBlendMode);
						}
						else if (Data._DiffuseBlendMode == BLEND_MODE_REPLACE && i < PreSkinColorDecalDataTexel)
						{	
							if (AlmostEquals(GH_PdxTex2DArrayLoad(DecalDiffuseArray, int3(9, 1, int(Data._DiffuseIndex)), int(CurrentLOD)).rgb, float3(0.0f,0.0f,1.0f)) )
							{
								float4 DiffuseSample = PdxTex2D( DecalDiffuseArray, float3( DecalUV, Data._DiffuseIndex ) );
								ColorPalette = lerp(ColorPalette,DragonSecondaryColor,DiffuseSample.a*Weight*ColorMask.r);
							}
							else if (AlmostEquals(GH_PdxTex2DArrayLoad(DecalDiffuseArray, int3(9, 1, int(Data._DiffuseIndex)), int(CurrentLOD)).rgb, float3(1.0f,1.0f,0.0f)) )
							{
								float4 DiffuseSample = PdxTex2D( DecalDiffuseArray, float3( DecalUV, Data._DiffuseIndex ) );
								ColorPalette = lerp(ColorPalette,DragonTertiaryColor,DiffuseSample.a*Weight*ColorMask.r);
							}
							else
							{
								float4 DiffuseSample = PdxTex2D( DecalDiffuseArray, float3( DecalUV, Data._DiffuseIndex ) );
								ColorPalette = lerp(ColorPalette,DiffuseSample.rgb,DiffuseSample.a*Weight*ColorMask.r);
							}

						}
						else
						{
							Weight *= TilingMaskSample;
							float4 DiffuseSample = PdxTex2D( DecalDiffuseArray, float3( DecalUV, Data._DiffuseIndex ) );
							Diffuse = BlendDecal( Data._DiffuseBlendMode, Diffuse, DiffuseSample, Weight );
						}
					}

					//Normal Decal
					if (AlmostEquals(GH_PdxTex2DArrayLoad(DecalNormalArray, int3(5, 1, int(Data._NormalIndex)), int(CurrentLOD)).rgb, DRAGON_BODYPART_MARKER) )
					{
						//Dragon wound decal
						if (AlmostEquals(GH_PdxTex2DArrayLoad(DecalNormalArray, int3(9, 1, int(Data._NormalIndex)), int(CurrentLOD)).rgb, float3(1.0f,0.0f,0.0f)) )
						{
							float4 DamageNormals = float4( Normals, 0.0f );
							ApplyDragonDamageDecal(DamageNormals, NORMAL_DECAL, Weight, RandomSeed, 0, UV1, int(Data._NormalIndex),Data._NormalBlendMode);
							Normals = DamageNormals.xyz;
						}
						//Dragon scar decal
						else if (AlmostEquals(GH_PdxTex2DArrayLoad(DecalNormalArray, int3(9, 1, int(Data._NormalIndex)), int(CurrentLOD)).rgb, float3(0.0f,1.0f,0.0f)) )
						{
							float4 DamageNormals = float4( Normals, 0.0f );
							ApplyDragonDamageDecal(DamageNormals, NORMAL_DECAL, Weight, RandomSeed, 1, UV1, int(Data._NormalIndex),Data._NormalBlendMode);
							Normals = DamageNormals.xyz;
						}
						else
						{
							float3 NormalSample = UnpackDecalNormal( PdxTex2D( DecalNormalArray, float3( DecalUV, Data._NormalIndex ) ), Weight );
							Normals = BlendDecal( Data._NormalBlendMode, float4( Normals, 0.0f ), float4( NormalSample, 0.0f ), Weight ).xyz;
						}

					}

					//Properties Decals
					if (AlmostEquals(GH_PdxTex2DArrayLoad(DecalPropertiesArray, int3(5, 1, int(Data._PropertiesIndex)), int(CurrentLOD)).rgb, DRAGON_BODYPART_MARKER) )
					{
						//Dragon wound decal
						if (AlmostEquals(GH_PdxTex2DArrayLoad(DecalPropertiesArray, int3(9, 1, int(Data._PropertiesIndex)), int(CurrentLOD)).rgb, float3(1.0f,0.0f,0.0f)) )
						{
							ApplyDragonDamageDecal(Properties, PROPERTIES_DECAL, Weight, RandomSeed, 0, UV1, int(Data._PropertiesIndex),Data._PropertiesBlendMode);
						}
						else
						{
							float4 PropertiesSample = PdxTex2D( DecalPropertiesArray, float3( DecalUV, Data._PropertiesIndex ) );
							Properties = BlendDecal( Data._PropertiesBlendMode, Properties, PropertiesSample, Weight );
						}
					}
				}

				//Apply dragon colours
				if (i == PreSkinColorDecalDataTexel-GH_VANILLA_TEXEL_COUNT_PER_DECAL)
				{
					Diffuse.rgb *= ColorPalette;
				}
			}
			Normals = normalize( Normals );
		}
		#endif
	]]
}
