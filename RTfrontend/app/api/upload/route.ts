import { NextRequest, NextResponse } from 'next/server';
import { writeFile, mkdir } from 'fs/promises';
import { join } from 'path';
import { cwd } from 'process';
import { existsSync } from 'fs';

// Receives an uploaded accident video and stores it under public/uploads so the
// FastAPI backend can read it from disk (video_url paths starting with "/" are
// resolved against ../frontend/public). Returns the public URL of the saved file.
export async function POST(request: NextRequest) {
	try {
		const formData = await request.formData();
		const video = formData.get('video') as File | null;

		if (!video) {
			return NextResponse.json(
				{ error: 'No video file provided' },
				{ status: 400 }
			);
		}

		if (!video.type.startsWith('video/')) {
			return NextResponse.json(
				{ error: 'File must be a video' },
				{ status: 400 }
			);
		}

		const fileName = `${Date.now()}-${video.name.replace(/\s+/g, '_')}`;
		const uploadDir = join(cwd(), 'public', 'uploads');

		if (!existsSync(uploadDir)) {
			await mkdir(uploadDir, { recursive: true });
		}

		const filePath = join(uploadDir, fileName);
		const buffer = Buffer.from(await video.arrayBuffer());
		await writeFile(filePath, buffer);

		return NextResponse.json(
			{ videoUrl: `/uploads/${fileName}` },
			{ status: 201 }
		);
	} catch (error) {
		console.error('Error uploading video:', error);
		return NextResponse.json(
			{ error: 'Internal server error', details: (error as Error).message },
			{ status: 500 }
		);
	}
}
