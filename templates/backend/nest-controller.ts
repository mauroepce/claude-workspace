// NestJS controller + service + DTO pattern. Class-validator for input.
// Pattern relevant for Carvuk, Property Partners, any Nest-based backend.
//
// Dependencies: @nestjs/common, class-validator, class-transformer
//   npm install @nestjs/common class-validator class-transformer
//
// File layout (copy as separate files in real project):
//   src/users/dto/create-user.dto.ts
//   src/users/users.service.ts
//   src/users/users.controller.ts
//   src/users/users.module.ts

import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  HttpCode,
  NotFoundException,
  Injectable,
  Module,
} from "@nestjs/common";
import {
  IsEmail,
  IsString,
  IsInt,
  IsOptional,
  Min,
  Max,
  MaxLength,
  MinLength,
} from "class-validator";

// ─── DTO ─────────────────────────────────────────────────────────────────────
// class-validator decorators run when ValidationPipe is global (in main.ts).
// Reject bad input at the boundary, types alone aren't enough.

export class CreateUserDto {
  @IsEmail()
  email!: string;

  @IsString()
  @MinLength(1)
  @MaxLength(100)
  name!: string;

  @IsInt()
  @Min(18)
  @Max(120)
  @IsOptional()
  age?: number;
}

// ─── Domain types ────────────────────────────────────────────────────────────

export interface User {
  id: string;
  email: string;
  name: string;
  age?: number;
  createdAt: Date;
}

// ─── Service ─────────────────────────────────────────────────────────────────
// Business logic lives here. Controllers stay thin.
// Replace the in-memory Map with a real repository (Prisma/Drizzle/TypeORM).

@Injectable()
export class UsersService {
  private readonly users = new Map<string, User>();

  async create(dto: CreateUserDto): Promise<User> {
    const user: User = {
      id: crypto.randomUUID(),
      email: dto.email,
      name: dto.name,
      age: dto.age,
      createdAt: new Date(),
    };
    this.users.set(user.id, user);
    return user;
  }

  async findOne(id: string): Promise<User | null> {
    return this.users.get(id) ?? null;
  }

  async findAll(): Promise<User[]> {
    return Array.from(this.users.values());
  }
}

// ─── Controller ──────────────────────────────────────────────────────────────
// Just routing + delegation. No business logic.

@Controller("users")
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Post()
  @HttpCode(201)
  async create(@Body() dto: CreateUserDto): Promise<User> {
    return this.usersService.create(dto);
  }

  @Get(":id")
  async findOne(@Param("id") id: string): Promise<User> {
    const user = await this.usersService.findOne(id);
    if (!user) throw new NotFoundException(`User ${id} not found`);
    return user;
  }

  @Get()
  async findAll(): Promise<User[]> {
    return this.usersService.findAll();
  }
}

// ─── Module ──────────────────────────────────────────────────────────────────
// Wire controller + service. Import this module into AppModule.

@Module({
  controllers: [UsersController],
  providers: [UsersService],
  exports: [UsersService],
})
export class UsersModule {}

// ─── Reminder for main.ts ────────────────────────────────────────────────────
// Enable global validation pipe to make DTO decorators actually run:
//
// import { ValidationPipe } from "@nestjs/common";
// app.useGlobalPipes(new ValidationPipe({
//   whitelist: true,         // strip unknown props
//   forbidNonWhitelisted: true,  // reject unknown props
//   transform: true,         // convert payload to DTO instance
// }));
