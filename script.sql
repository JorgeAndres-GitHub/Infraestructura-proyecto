CREATE TABLE Usuarios (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Nombre NVARCHAR(100) NOT NULL,
    Email NVARCHAR(150) NOT NULL UNIQUE
);

CREATE TABLE Productos (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Nombre NVARCHAR(100) NOT NULL,
    Precio DECIMAL(10,2) NOT NULL
);

INSERT INTO Usuarios (Nombre, Email)
VALUES ('Jorge', 'jorge@example.com');

INSERT INTO Productos (Nombre, Precio)
VALUES ('Laptop', 3500.00);
