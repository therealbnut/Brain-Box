#ifndef _BB_VECTOR3_H_

#include <cmath>
#include <assert.h>

namespace BB
{
	template <typename Scalar>
	struct Vector3
	{
	public:
		template <typename Scalar2>
		inline Vector3(const Scalar2 coords[3]);
		inline Vector3(const Scalar& _x, const Scalar& _y, const Scalar& _z);
		inline Vector3(const Vector3& that);
		inline Vector3();
		
		inline Vector3& operator = (const Vector3& that);

		inline Scalar dot(const Vector3& that) const;
		inline Scalar distance(const Vector3& that) const;
		inline Scalar length() const;
		
		inline Vector3 normalize(void) const;
		inline Vector3 cross(const Vector3& that) const;
		
		inline Vector3 operator - (void) const;
		inline Scalar operator [] (unsigned int i) const;
		
		inline Vector3 operator * (Scalar v) const;
		template<typename Scalar2>
		friend inline Vector3<Scalar2> operator * (Scalar2 v, const Vector3<Scalar2>& that);

		inline Vector3 operator + (const Vector3& that) const;
		inline Vector3 operator - (const Vector3& that) const;
		inline Vector3 operator * (const Vector3& that) const;
		inline Vector3 operator / (const Vector3& that) const;
		
		inline Vector3& operator += (const Vector3& that);
		inline Vector3& operator -= (const Vector3& that);
		inline Vector3& operator *= (const Vector3& that);
		inline Vector3& operator /= (const Vector3& that);

		Scalar x, y, z;
	};

#pragma mark Assignment
	template <typename Scalar>
	template <typename Scalar2>
	inline Vector3<Scalar>::Vector3(const Scalar2 coords[3])
	: x(coords[0]), y(coords[1]), z(coords[2])
	{
	}	
	template <typename Scalar>
	inline Vector3<Scalar>::Vector3(const Scalar& _x, const Scalar& _y, const Scalar& _z)
		: x(_x), y(_y), z(_z)
	{
	}
	template <typename Scalar>
	inline Vector3<Scalar>::Vector3(const Vector3& that)
		: x(that.x), y(that.y), z(that.z)
	{
	}
	template <typename Scalar>
	inline Vector3<Scalar>::Vector3()
	: x(0.0), y(0.0), z(0.0)
	{
	}
	template <typename Scalar>
	inline Vector3<Scalar>& Vector3<Scalar>::operator = (const Vector3& that)
	{
		this->x = that.x; this->y = that.y; this->z = that.z;
		return *this;
	}	

#pragma mark Functions mapping to Scalar
	template <typename Scalar>
	inline Scalar Vector3<Scalar>::dot(const Vector3& that) const
	{
		return x*that.x + y*that.y + z*that.z;
	}
	template <typename Scalar>
	inline Scalar Vector3<Scalar>::distance(const Vector3& that) const
	{
		return Vector3(x-that.x, y-that.y, z-that.z).length();
	}
	template <typename Scalar>
	inline Scalar Vector3<Scalar>::length() const
	{
		return sqrt(x*x + y*y + z*z);
	}

#pragma mark Functions mapping to Vectors
	template <typename Scalar>
	inline Vector3<Scalar> Vector3<Scalar>::normalize(void) const
	{
		Scalar len = this->length();
		return Vector3(x/len, y/len, z/len);
	}
	
	template <typename Scalar>
	inline Vector3<Scalar> Vector3<Scalar>::cross(const Vector3& that) const
	{
		return Vector3(y * that.z - z * that.y, z * that.x - x * that.z, x * that.y - y * that.x);
	}

#pragma mark Misc Operators
	template <typename Scalar>
	inline Vector3<Scalar> Vector3<Scalar>::operator - (void) const
	{
		return Vector3(-x,-y,-z);
	}
	
	template <typename Scalar>
	inline Scalar Vector3<Scalar>::operator [] (unsigned int i) const
	{
		assert(i < 3);
		return (&x)[i];
	}

#pragma mark Operators taking a Scalar and Producing a new Vector
	template <typename Scalar>
	inline Vector3<Scalar> Vector3<Scalar>::operator * (Scalar v) const
	{
		return Vector3(x*v, y*v, z*v);
	}
	
	template <typename Scalar>
	inline Vector3<Scalar> operator * (Scalar v, const Vector3<Scalar>& that)
	{
		return Vector3<Scalar>(that.x*v, that.y*v, that.z*v);
	}

#pragma mark Operators producing a new Vector
	template <typename Scalar>
	inline Vector3<Scalar> Vector3<Scalar>::operator + (const Vector3& that) const
	{
		return Vector3(x+that.x, y+that.y, z+that.z);
	}
	template <typename Scalar>
	inline Vector3<Scalar> Vector3<Scalar>::operator - (const Vector3& that) const
	{
		return Vector3(x-that.x, y-that.y, z-that.z);
	}
	template <typename Scalar>
	inline Vector3<Scalar> Vector3<Scalar>::operator * (const Vector3& that) const
	{
		return Vector3(x*that.x, y*that.y, z*that.z);
	}
	template <typename Scalar>
	inline Vector3<Scalar> Vector3<Scalar>::operator / (const Vector3& that) const
	{
		return Vector3(x/that.x, y/that.y, z/that.z);
	}

#pragma mark Operators updating a Vector
	template <typename Scalar>
	inline Vector3<Scalar>& Vector3<Scalar>::operator += (const Vector3& that)
	{
		x+=that.x; y+=that.y; z+=that.z;
		return *this;
	}
	template <typename Scalar>
	inline Vector3<Scalar>& Vector3<Scalar>::operator -= (const Vector3& that)
	{
		x-=that.x; y-=that.y; z-=that.z;
		return *this;
	}
	template <typename Scalar>
	inline Vector3<Scalar>& Vector3<Scalar>::operator *= (const Vector3& that)
	{
		x*=that.x; y*=that.y; z*=that.z;
		return *this;
	}
	template <typename Scalar>
	inline Vector3<Scalar>& Vector3<Scalar>::operator /= (const Vector3& that)
	{
		x/=that.x; y/=that.y; z/=that.z;
		return *this;
	}
}

#endif
