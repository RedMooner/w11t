-- Создание базы данных
CREATE DATABASE PizzaDB COLLATE Cyrillic_General_CI_AS;
GO

USE PizzaDB;
GO

-- ============================================
-- СПРАВОЧНИКИ
-- ============================================

-- Таблица ролей сотрудников
CREATE TABLE EmployeeRoles (
    RoleID INT IDENTITY(1,1) PRIMARY KEY,
    RoleName NVARCHAR(50) NOT NULL UNIQUE
);
GO

-- Таблица категорий блюд
CREATE TABLE DishCategories (
    CategoryID INT IDENTITY(1,1) PRIMARY KEY,
    CategoryName NVARCHAR(50) NOT NULL UNIQUE
);
GO

-- Таблица способов оплаты
CREATE TABLE PaymentMethods (
    PaymentMethodID INT IDENTITY(1,1) PRIMARY KEY,
    PaymentMethodName NVARCHAR(30) NOT NULL UNIQUE
);
GO

-- Таблица типов доставки
CREATE TABLE DeliveryTypes (
    DeliveryTypeID INT IDENTITY(1,1) PRIMARY KEY,
    DeliveryTypeName NVARCHAR(20) NOT NULL UNIQUE
);
GO

-- Таблица статусов заказа
CREATE TABLE OrderStatuses (
    StatusID INT IDENTITY(1,1) PRIMARY KEY,
    StatusName NVARCHAR(30) NOT NULL UNIQUE
);
GO

-- Таблица единиц измерения
CREATE TABLE Units (
    UnitID INT IDENTITY(1,1) PRIMARY KEY,
    UnitName NVARCHAR(20) NOT NULL UNIQUE
);
GO

-- Таблица типов назначений сотрудников
CREATE TABLE AssignmentTypes (
    AssignmentTypeID INT IDENTITY(1,1) PRIMARY KEY,
    AssignmentTypeName NVARCHAR(20) NOT NULL UNIQUE
);
GO

-- ============================================
-- ЗАПОЛНЕНИЕ СПРАВОЧНИКОВ
-- ============================================

INSERT INTO EmployeeRoles (RoleName) VALUES 
(N'Повар'),
(N'Курьер'),
(N'Оператор');

INSERT INTO DishCategories (CategoryName) VALUES 
(N'Пицца'),
(N'Закуска'),
(N'Напиток'),
(N'Салат'),
(N'Десерт');

INSERT INTO PaymentMethods (PaymentMethodName) VALUES 
(N'Карта онлайн'),
(N'Наличные курьеру'),
(N'Карта курьеру');

INSERT INTO DeliveryTypes (DeliveryTypeName) VALUES 
(N'Доставка'),
(N'Самовывоз');

INSERT INTO OrderStatuses (StatusName) VALUES 
(N'Принят'),
(N'Готовится'),
(N'Готов'),
(N'Передан курьеру'),
(N'Доставлен'),
(N'Выдан на месте');

INSERT INTO Units (UnitName) VALUES 
(N'кг'),
(N'г'),
(N'л'),
(N'мл'),
(N'шт');

INSERT INTO AssignmentTypes (AssignmentTypeName) VALUES 
(N'Повар'),
(N'Курьер');

-- ============================================
-- ОСНОВНЫЕ ТАБЛИЦЫ
-- ============================================

-- Таблица сотрудников
CREATE TABLE Employees (
    EmployeeID INT IDENTITY(1,1) PRIMARY KEY,
    FullName NVARCHAR(100) NOT NULL,
    PhoneNumber NVARCHAR(20) NOT NULL UNIQUE,
    RoleID INT NOT NULL FOREIGN KEY REFERENCES EmployeeRoles(RoleID),
    HireDate DATE NOT NULL DEFAULT GETDATE()
);
GO

-- Таблица клиентов
CREATE TABLE Clients (
    ClientID INT IDENTITY(1,1) PRIMARY KEY,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    PhoneNumber NVARCHAR(20) NOT NULL UNIQUE,
    Email NVARCHAR(100) UNIQUE,
    RegistrationDate DATETIME NOT NULL DEFAULT GETDATE()
);
GO

-- Таблица адресов доставки
CREATE TABLE DeliveryAddresses (
    AddressID INT IDENTITY(1,1) PRIMARY KEY,
    ClientID INT NOT NULL FOREIGN KEY REFERENCES Clients(ClientID) ON DELETE CASCADE,
    Street NVARCHAR(100) NOT NULL,
    House NVARCHAR(20) NOT NULL,
    Building NVARCHAR(20),
    Apartment NVARCHAR(20),
    Floor NVARCHAR(10),
    IntercomCode NVARCHAR(20),
    IsDefault BIT DEFAULT 0
);
GO

-- Таблица ингредиентов
CREATE TABLE Ingredients (
    IngredientID INT IDENTITY(1,1) PRIMARY KEY,
    ArticleNumber NVARCHAR(50) NOT NULL UNIQUE,
    Name NVARCHAR(100) NOT NULL,
    UnitID INT NOT NULL FOREIGN KEY REFERENCES Units(UnitID),
    QuantityInStock DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (QuantityInStock >= 0)
);
GO

-- Таблица блюд
CREATE TABLE Dishes (
    DishID INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    CategoryID INT NOT NULL FOREIGN KEY REFERENCES DishCategories(CategoryID),
    CookingTimeMinutes INT NOT NULL CHECK (CookingTimeMinutes > 0),
    BasePrice DECIMAL(10,2) NOT NULL CHECK (BasePrice > 0),
    Description NVARCHAR(500)
);
GO

-- Связь блюд с ингредиентами (состав блюда)
CREATE TABLE DishIngredients (
    DishIngredientID INT IDENTITY(1,1) PRIMARY KEY,
    DishID INT NOT NULL FOREIGN KEY REFERENCES Dishes(DishID) ON DELETE CASCADE,
    IngredientID INT NOT NULL FOREIGN KEY REFERENCES Ingredients(IngredientID),
    Quantity DECIMAL(10,2) NOT NULL CHECK (Quantity > 0)
);
GO

-- Таблица заказов
CREATE TABLE Orders (
    OrderID INT IDENTITY(1,1) PRIMARY KEY,
    OrderNumber AS ('ORD-' + RIGHT('00000' + CAST(OrderID AS VARCHAR(5)), 5)) PERSISTED,
    ClientID INT NOT NULL FOREIGN KEY REFERENCES Clients(ClientID),
    EmployeeID INT NOT NULL FOREIGN KEY REFERENCES Employees(EmployeeID), 
    AddressID INT FOREIGN KEY REFERENCES DeliveryAddresses(AddressID),
    DeliveryTypeID INT NOT NULL FOREIGN KEY REFERENCES DeliveryTypes(DeliveryTypeID),
    PaymentMethodID INT NOT NULL FOREIGN KEY REFERENCES PaymentMethods(PaymentMethodID),
    OrderStatusID INT NOT NULL DEFAULT 1 FOREIGN KEY REFERENCES OrderStatuses(StatusID), 
    ContactPhone NVARCHAR(20) NOT NULL,
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    PlannedReadyTime DATETIME,
    ActualReadyTime DATETIME,
    DeliveryCost DECIMAL(10,2) DEFAULT 0 CHECK (DeliveryCost >= 0),
    Notes NVARCHAR(500)
);
GO

-- Таблица назначений сотрудников на заказ
CREATE TABLE OrderAssignments (
    AssignmentID INT IDENTITY(1,1) PRIMARY KEY,
    OrderID INT NOT NULL FOREIGN KEY REFERENCES Orders(OrderID) ON DELETE CASCADE,
    EmployeeID INT NOT NULL FOREIGN KEY REFERENCES Employees(EmployeeID),
    AssignmentTypeID INT NOT NULL FOREIGN KEY REFERENCES AssignmentTypes(AssignmentTypeID),
    AssignedAt DATETIME NOT NULL DEFAULT GETDATE(),
    CompletedAt DATETIME,
    Notes NVARCHAR(500),
    UNIQUE (OrderID, EmployeeID, AssignmentTypeID)
);
GO

-- Таблица позиций в заказе
CREATE TABLE OrderItems (
    OrderItemID INT IDENTITY(1,1) PRIMARY KEY,
    OrderID INT NOT NULL FOREIGN KEY REFERENCES Orders(OrderID) ON DELETE CASCADE,
    DishID INT NOT NULL FOREIGN KEY REFERENCES Dishes(DishID),
    Quantity INT NOT NULL CHECK (Quantity > 0),
    SpecialRequest NVARCHAR(500),
    CookingStartTime DATETIME,
    CookingEndTime DATETIME,
    CHECK (CookingEndTime >= CookingStartTime OR (CookingStartTime IS NULL AND CookingEndTime IS NULL))
);
GO

-- Индексы
CREATE INDEX IX_Orders_ClientID ON Orders(ClientID);
CREATE INDEX IX_Orders_EmployeeID ON Orders(EmployeeID);
CREATE INDEX IX_Orders_OrderStatusID ON Orders(OrderStatusID);
CREATE INDEX IX_Orders_CreatedAt ON Orders(CreatedAt);
CREATE INDEX IX_OrderItems_OrderID ON OrderItems(OrderID);
CREATE INDEX IX_OrderAssignments_OrderID ON OrderAssignments(OrderID);
GO

-- ============================================
-- ЗАПОЛНЕНИЕ ТЕСТОВЫМИ ДАННЫМИ
-- ============================================

-- Сотрудники
INSERT INTO Employees (FullName, PhoneNumber, RoleID, HireDate) VALUES
(N'Иванов Иван Иванович', '+7(999)123-45-67', 1, '2025-01-15'), -- Повар
(N'Петров Петр Петрович', '+7(999)234-56-78', 1, '2025-02-10'), -- Повар
(N'Сидорова Анна Сергеевна', '+7(999)345-67-89', 1, '2025-03-05'), -- Повар
(N'Козлов Дмитрий Андреевич', '+7(999)456-78-90', 2, '2025-01-20'), -- Курьер
(N'Морозова Елена Владимировна', '+7(999)567-89-01', 2, '2025-02-15'), -- Курьер
(N'Волков Александр Игоревич', '+7(999)678-90-12', 3, '2025-01-10'), -- Оператор
(N'Соколова Татьяна Михайловна', '+7(999)789-01-23', 3, '2025-03-01'); -- Оператор
GO

-- Клиенты
INSERT INTO Clients (FirstName, LastName, PhoneNumber, Email) VALUES
(N'Алексей', N'Смирнов', '+7(901)111-22-33', 'alexey.smirnov@email.com'),
(N'Елена', N'Кузнецова', '+7(902)222-33-44', 'elena.k@email.com'),
(N'Дмитрий', N'Попов', '+7(903)333-44-55', 'dmitry.popov@email.com'),
(N'Ольга', N'Васильева', '+7(904)444-55-66', 'olga.vas@email.com'),
(N'Михаил', N'Соколов', '+7(905)555-66-77', NULL);
GO

-- Адреса доставки
INSERT INTO DeliveryAddresses (ClientID, Street, House, Building, Apartment, Floor, IntercomCode, IsDefault) VALUES
(1, N'Ленина', N'15', NULL, N'42', N'5', N'42', 1),
(1, N'Гагарина', N'7', N'А', N'15', N'3', N'15', 0),
(2, N'Пушкина', N'23', NULL, N'78', N'9', N'78', 1),
(3, N'Советская', N'5', NULL, N'12', N'2', N'12', 1),
(4, N'Мира', N'42', N'Б', N'56', N'7', N'56', 1);
GO

-- Ингредиенты
INSERT INTO Ingredients (ArticleNumber, Name, UnitID, QuantityInStock) VALUES
('ING-001', N'Мука пшеничная', 1, 50.5),  -- кг
('ING-002', N'Томатный соус', 3, 30.0),   -- л
('ING-003', N'Сыр моцарелла', 1, 25.0),   -- кг
('ING-004', N'Пепперони', 1, 15.0),       -- кг
('ING-005', N'Шампиньоны', 1, 20.0),      -- кг
('ING-006', N'Куриное филе', 1, 30.0),    -- кг
('ING-007', N'Помидоры', 1, 18.0),        -- кг
('ING-008', N'Огурцы', 1, 15.0),          -- кг
('ING-009', N'Листья салата', 1, 8.0),    -- кг
('ING-010', N'Кола', 3, 100.0);           -- л
GO

-- Блюда
INSERT INTO Dishes (Name, CategoryID, CookingTimeMinutes, BasePrice, Description) VALUES
(N'Пицца Маргарита', 1, 15, 350.00, N'Томатный соус, моцарелла, базилик'),          -- Пицца
(N'Пицца Пепперони', 1, 18, 450.00, N'Томатный соус, моцарелла, пепперони'),        -- Пицца
(N'Пицца Грибная', 1, 20, 420.00, N'Томатный соус, моцарелла, шампиньоны, лук'),    -- Пицца
(N'Салат Цезарь', 4, 10, 280.00, N'Куриное филе, листья салата, помидоры, соус'),   -- Салат
(N'Греческий салат', 4, 8, 250.00, N'Помидоры, огурцы, сыр фета, маслины'),         -- Салат
(N'Кола 0.5л', 3, 1, 100.00, N'Напиток прохладительный');                            -- Напиток
GO

-- Состав блюд
INSERT INTO DishIngredients (DishID, IngredientID, Quantity) VALUES
(1, 1, 0.3), (1, 2, 0.1), (1, 3, 0.2),  -- Маргарита
(2, 1, 0.3), (2, 2, 0.1), (2, 3, 0.2), (2, 4, 0.15),  -- Пепперони
(3, 1, 0.3), (3, 2, 0.1), (3, 3, 0.2), (3, 5, 0.15),  -- Грибная
(4, 6, 0.15), (4, 7, 0.1), (4, 9, 0.1),  -- Цезарь
(5, 7, 0.15), (5, 8, 0.15);  -- Греческий
GO

-- Заказы 
INSERT INTO Orders (ClientID, EmployeeID, AddressID, DeliveryTypeID, PaymentMethodID, ContactPhone, CreatedAt, PlannedReadyTime, ActualReadyTime, DeliveryCost, Notes, OrderStatusID)
VALUES
(1, 6, 1, 1, 1, '+7(901)111-22-33', '2026-02-23 10:00:00', '2026-02-23 11:00:00', '2026-02-23 11:00:00', 100, N'Позвонить за 5 минут', 5),  -- Доставлен
(2, 7, 3, 1, 2, '+7(902)222-33-44', '2026-02-23 07:00:00', '2026-02-23 08:00:00', '2026-02-23 08:00:00', 100, N'Код домофона 78', 5),  -- Доставлен
(3, 6, 4, 2, 3, '+7(903)333-44-55', '2026-02-23 11:00:00', '2026-02-23 12:00:00', NULL, 0, N'', 3),  -- Готов
(4, 7, NULL, 1, 1, '+7(904)444-55-66', '2026-02-23 12:00:00', '2026-02-23 12:30:00', NULL, 150, N'Домофон 5', 2);  -- Готовится
GO

-- Назначение сотрудников на заказы
INSERT INTO OrderAssignments (OrderID, EmployeeID, AssignmentTypeID, AssignedAt, CompletedAt) VALUES
(1, 1, 1, '2026-02-23 10:00:00', '2026-02-23 10:00:00'),  -- Повар
(1, 4, 2, '2026-02-23 10:00:00', '2026-02-23 11:00:00'),  -- Курьер
(2, 2, 1, '2026-02-23 07:00:00', '2026-02-23 07:00:00'),  -- Повар
(2, 5, 2, '2026-02-23 07:00:00', '2026-02-23 08:00:00'),  -- Курьер
(3, 3, 1, '2026-02-23 11:00:00', '2026-02-23 11:00:00'),  -- Повар
(4, 1, 1, '2026-02-23 12:00:00', NULL);                    -- Повар
GO

-- Позиции в заказах
INSERT INTO OrderItems (OrderID, DishID, Quantity, SpecialRequest, CookingStartTime, CookingEndTime) VALUES
-- Заказ 1
(1, 1, 2, NULL, '2026-02-23 10:00:00', '2026-02-23 10:00:00'),
(1, 4, 1, N'Соус отдельно', '2026-02-23 10:00:00', '2026-02-23 10:00:00'),
(1, 6, 2, NULL, NULL, NULL),
-- Заказ 2
(2, 2, 1, N'Поострее', '2026-02-23 07:00:00', '2026-02-23 07:00:00'),
(2, 5, 1, NULL, '2026-02-23 07:00:00', '2026-02-23 07:00:00'),
-- Заказ 3
(3, 3, 1, NULL, '2026-02-23 11:00:00', '2026-02-23 11:00:00'),
(3, 6, 1, N'Без льда', NULL, NULL),
-- Заказ 4
(4, 1, 1, NULL, '2026-02-23 12:00:00', NULL),
(4, 2, 1, N'Без оливок', '2026-02-23 12:00:00', NULL);
GO